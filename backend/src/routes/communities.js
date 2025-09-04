const express = require('express');
const { body, validationResult } = require('express-validator');
const { query } = require('../database/connection');
const { requireOwnerOrAdmin, requireAdminOrHigher } = require('../middleware/auth');
const { createAuditLog } = require('../services/auditService');
const { sendInviteEmail } = require('../services/emailService');

const router = express.Router();

// Validation middleware
const validateCommunityCreation = [
  body('handle').matches(/^[a-z0-9-]+$/).withMessage('Handle must contain only lowercase letters, numbers, and hyphens'),
  body('name').trim().isLength({ min: 1, max: 255 }),
  body('email').isEmail().normalizeEmail(),
  body('phoneNumber').optional().isMobilePhone(),
  body('address').optional().trim(),
  body('city').optional().trim(),
  body('state').optional().trim(),
  body('zip').optional().trim(),
  body('country').optional().trim(),
  body('collaborators').isArray({ min: 0, max: 10 }),
  body('collaborators.*.email').isEmail().normalizeEmail(),
  body('collaborators.*.role').isIn(['admin', 'limited_admin', 'viewer'])
];

const validateCommunityUpdate = [
  body('name').optional().trim().isLength({ min: 1, max: 255 }),
  body('email').optional().isEmail().normalizeEmail(),
  body('phoneNumber').optional().isMobilePhone(),
  body('address').optional().trim(),
  body('city').optional().trim(),
  body('state').optional().trim(),
  body('zip').optional().trim(),
  body('country').optional().trim()
];

// Get all communities user has access to
router.get('/', async (req, res) => {
  try {
    const result = await query(
      `SELECT c.*, 
              up.first_name as creator_first_name, 
              up.last_name as creator_last_name,
              col.role as user_role,
              col.status as user_status
       FROM communities c
       JOIN collaborators col ON c.id = col.community_id
       JOIN users u ON c.created_by = u.id
       JOIN user_profiles up ON u.id = up.user_id
       WHERE col.user_id = $1
       ORDER BY c.created_at DESC`,
      [req.user.id]
    );

    res.json(result.rows);
  } catch (error) {
    console.error('Get communities error:', error);
    res.status(500).json({ error: 'Failed to fetch communities' });
  }
});

// Get community by ID
router.get('/:communityId', async (req, res) => {
  try {
    const { communityId } = req.params;

    const result = await query(
      `SELECT c.*, 
              up.first_name as creator_first_name, 
              up.last_name as creator_last_name,
              col.role as user_role,
              col.status as user_status
       FROM communities c
       JOIN collaborators col ON c.id = col.community_id
       JOIN users u ON c.created_by = u.id
       JOIN user_profiles up ON u.id = up.user_id
       WHERE c.id = $1 AND col.user_id = $2`,
      [communityId, req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Community not found' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Get community error:', error);
    res.status(500).json({ error: 'Failed to fetch community' });
  }
});

// Create new community
router.post('/', validateCommunityCreation, async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { 
      handle, name, email, phoneNumber, address, city, state, zip, country, collaborators 
    } = req.body;

    // Check if handle is unique
    const existingCommunity = await query(
      'SELECT id FROM communities WHERE handle = $1',
      [handle]
    );

    if (existingCommunity.rows.length > 0) {
      return res.status(409).json({ error: 'Community handle already exists' });
    }

    // Start transaction
    const client = await query.getClient();
    
    try {
      await client.query('BEGIN');

      // Create community
      const communityResult = await client.query(
        `INSERT INTO communities (handle, name, email, phone_number, address, city, state, zip, country, created_by) 
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) RETURNING *`,
        [handle, name, email, phoneNumber, address, city, state, zip, country, req.user.id]
      );

      const community = communityResult.rows[0];

      // Add creator as owner
      await client.query(
        'INSERT INTO collaborators (user_id, community_id, role, status) VALUES ($1, $2, $3, $4)',
        [req.user.id, community.id, 'owner', 'approved']
      );

      // Process collaborators
      for (const collaborator of collaborators) {
        // Check if user exists
        const userResult = await client.query(
          'SELECT id FROM users WHERE email = $1',
          [collaborator.email]
        );

        if (userResult.rows.length > 0) {
          // User exists, add as collaborator
          await client.query(
            'INSERT INTO collaborators (user_id, community_id, role, status) VALUES ($1, $2, $3, $4)',
            [userResult.rows[0].id, community.id, collaborator.role, 'pending']
          );
        } else {
          // User doesn't exist, create invite
          const inviteToken = require('crypto').randomBytes(32).toString('hex');
          const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days

          await client.query(
            'INSERT INTO invites (email, community_id, role, token, expires_at, created_by) VALUES ($1, $2, $3, $4, $5, $6)',
            [collaborator.email, community.id, collaborator.role, inviteToken, expiresAt, req.user.id]
          );

          // Send invite email
          await sendInviteEmail(collaborator.email, community.name, inviteToken);
        }
      }

      await client.query('COMMIT');

      // Create audit log
      await createAuditLog({
        userId: req.user.id,
        communityId: community.id,
        action: 'community_created',
        tableName: 'communities',
        recordId: community.id,
        newValues: { handle, name, email }
      });

      res.status(201).json({
        message: 'Community created successfully',
        community
      });

    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }

  } catch (error) {
    console.error('Create community error:', error);
    res.status(500).json({ error: 'Failed to create community' });
  }
});

// Update community
router.put('/:communityId', requireOwnerOrAdmin, validateCommunityUpdate, async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { communityId } = req.params;
    const updateFields = req.body;

    // Build dynamic update query
    const setClause = [];
    const values = [];
    let paramCount = 1;

    Object.keys(updateFields).forEach(key => {
      if (key !== 'id' && key !== 'created_by' && key !== 'handle') {
        setClause.push(`${key} = $${paramCount}`);
        values.push(updateFields[key]);
        paramCount++;
      }
    });

    if (setClause.length === 0) {
      return res.status(400).json({ error: 'No valid fields to update' });
    }

    values.push(communityId);
    const queryText = `UPDATE communities SET ${setClause.join(', ')}, updated_at = NOW() WHERE id = $${paramCount} RETURNING *`;

    const result = await query(queryText, values);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Community not found' });
    }

    // Create audit log
    await createAuditLog({
      userId: req.user.id,
      communityId,
      action: 'community_updated',
      tableName: 'communities',
      recordId: communityId,
      newValues: updateFields
    });

    res.json({
      message: 'Community updated successfully',
      community: result.rows[0]
    });

  } catch (error) {
    console.error('Update community error:', error);
    res.status(500).json({ error: 'Failed to update community' });
  }
});

// Delete community
router.delete('/:communityId', requireOwner, async (req, res) => {
  try {
    const { communityId } = req.params;

    const result = await query(
      'DELETE FROM communities WHERE id = $1 AND created_by = $2 RETURNING *',
      [communityId, req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Community not found or access denied' });
    }

    // Create audit log
    await createAuditLog({
      userId: req.user.id,
      communityId,
      action: 'community_deleted',
      tableName: 'communities',
      recordId: communityId
    });

    res.json({ message: 'Community deleted successfully' });

  } catch (error) {
    console.error('Delete community error:', error);
    res.status(500).json({ error: 'Failed to delete community' });
  }
});

// Get community collaborators
router.get('/:communityId/collaborators', async (req, res) => {
  try {
    const { communityId } = req.params;

    const result = await query(
      `SELECT c.*, 
              up.first_name, 
              up.last_name,
              u.email,
              up.avatar_url
       FROM collaborators c
       JOIN users u ON c.user_id = u.id
       JOIN user_profiles up ON u.id = up.user_id
       WHERE c.community_id = $1
       ORDER BY c.role, c.joined_at`,
      [communityId]
    );

    res.json(result.rows);
  } catch (error) {
    console.error('Get collaborators error:', error);
    res.status(500).json({ error: 'Failed to fetch collaborators' });
  }
});

// Update collaborator role/status
router.put('/:communityId/collaborators/:collaboratorId', requireAdminOrHigher, async (req, res) => {
  try {
    const { communityId, collaboratorId } = req.params;
    const { role, status } = req.body;

    // Validate role and status
    if (role && !['admin', 'limited_admin', 'viewer'].includes(role)) {
      return res.status(400).json({ error: 'Invalid role' });
    }

    if (status && !['pending', 'approved', 'rejected'].includes(status)) {
      return res.status(400).json({ error: 'Invalid status' });
    }

    // Build update query
    const updateFields = [];
    const values = [];
    let paramCount = 1;

    if (role) {
      updateFields.push(`role = $${paramCount}`);
      values.push(role);
      paramCount++;
    }

    if (status) {
      updateFields.push(`status = $${paramCount}`);
      values.push(status);
      paramCount++;
    }

    if (updateFields.length === 0) {
      return res.status(400).json({ error: 'No fields to update' });
    }

    values.push(collaboratorId, communityId);
    const queryText = `UPDATE collaborators SET ${updateFields.join(', ')}, updated_at = NOW() WHERE id = $${paramCount} AND community_id = $${paramCount + 1} RETURNING *`;

    const result = await query(queryText, values);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Collaborator not found' });
    }

    // Create audit log
    await createAuditLog({
      userId: req.user.id,
      communityId,
      action: 'collaborator_updated',
      tableName: 'collaborators',
      recordId: collaboratorId,
      newValues: { role, status }
    });

    res.json({
      message: 'Collaborator updated successfully',
      collaborator: result.rows[0]
    });

  } catch (error) {
    console.error('Update collaborator error:', error);
    res.status(500).json({ error: 'Failed to update collaborator' });
  }
});

// Remove collaborator
router.delete('/:communityId/collaborators/:collaboratorId', requireAdminOrHigher, async (req, res) => {
  try {
    const { communityId, collaboratorId } = req.params;

    const result = await query(
      'DELETE FROM collaborators WHERE id = $1 AND community_id = $2 RETURNING *',
      [collaboratorId, communityId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Collaborator not found' });
    }

    // Create audit log
    await createAuditLog({
      userId: req.user.id,
      communityId,
      action: 'collaborator_removed',
      tableName: 'collaborators',
      recordId: collaboratorId
    });

    res.json({ message: 'Collaborator removed successfully' });

  } catch (error) {
    console.error('Remove collaborator error:', error);
    res.status(500).json({ error: 'Failed to remove collaborator' });
  }
});

// Get community invites
router.get('/:communityId/invites', requireAdminOrHigher, async (req, res) => {
  try {
    const { communityId } = req.params;

    const result = await query(
      `SELECT i.*, 
              up.first_name as inviter_first_name, 
              up.last_name as inviter_last_name
       FROM invites i
       JOIN users u ON i.created_by = u.id
       JOIN user_profiles up ON u.id = up.user_id
       WHERE i.community_id = $1
       ORDER BY i.created_at DESC`,
      [communityId]
    );

    res.json(result.rows);
  } catch (error) {
    console.error('Get invites error:', error);
    res.status(500).json({ error: 'Failed to fetch invites' });
  }
});

// Send new invite
router.post('/:communityId/invites', requireAdminOrHigher, async (req, res) => {
  try {
    const { communityId } = req.params;
    const { email, role } = req.body;

    if (!email || !role) {
      return res.status(400).json({ error: 'Email and role are required' });
    }

    if (!['admin', 'limited_admin', 'viewer'].includes(role)) {
      return res.status(400).json({ error: 'Invalid role' });
    }

    // Check if invite already exists
    const existingInvite = await query(
      'SELECT id FROM invites WHERE email = $1 AND community_id = $2',
      [email, communityId]
    );

    if (existingInvite.rows.length > 0) {
      return res.status(409).json({ error: 'Invite already exists for this email' });
    }

    // Generate invite token
    const inviteToken = require('crypto').randomBytes(32).toString('hex');
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days

    // Create invite
    const result = await query(
      'INSERT INTO invites (email, community_id, role, token, expires_at, created_by) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *',
      [email, communityId, role, inviteToken, expiresAt, req.user.id]
    );

    // Get community name for email
    const communityResult = await query(
      'SELECT name FROM communities WHERE id = $1',
      [communityId]
    );

    // Send invite email
    await sendInviteEmail(email, communityResult.rows[0].name, inviteToken);

    // Create audit log
    await createAuditLog({
      userId: req.user.id,
      communityId,
      action: 'invite_sent',
      tableName: 'invites',
      recordId: result.rows[0].id,
      newValues: { email, role }
    });

    res.status(201).json({
      message: 'Invite sent successfully',
      invite: result.rows[0]
    });

  } catch (error) {
    console.error('Send invite error:', error);
    res.status(500).json({ error: 'Failed to send invite' });
  }
});

module.exports = router;
