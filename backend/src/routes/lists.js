const express = require('express');
const { Pool } = require('pg');
const { authenticateToken } = require('../middleware/auth');
const { auditLog } = require('../services/auditService');

const router = express.Router();
const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
});

// Get all lists for a community
router.get('/communities/:communityId/lists', authenticateToken, async (req, res) => {
    try {
        const { communityId } = req.params;
        const userId = req.user.id;

        // Verify user has access to this community
        const communityAccess = await pool.query(
            'SELECT role FROM collaborators WHERE user_id = $1 AND community_id = $2 AND status = $3',
            [userId, communityId, 'approved']
        );

        if (communityAccess.rows.length === 0) {
            return res.status(403).json({ error: 'Access denied to this community' });
        }

        // Get all lists for the community
        const listsQuery = `
            SELECT 
                l.*,
                COUNT(ml.member_id) as member_count
            FROM lists l
            LEFT JOIN member_lists ml ON l.id = ml.list_id
            WHERE l.community_id = $1
            GROUP BY l.id
            ORDER BY l.is_default DESC, l.created_at ASC
        `;

        const result = await pool.query(listsQuery, [communityId]);
        
        res.json({
            lists: result.rows.map(row => ({
                id: row.id,
                communityId: row.community_id,
                name: row.name,
                description: row.description,
                color: row.color,
                emoji: row.emoji,
                isDefault: row.is_default,
                createdBy: row.created_by,
                createdAt: row.created_at,
                updatedAt: row.updated_at,
                memberCount: parseInt(row.member_count)
            }))
        });

    } catch (error) {
        console.error('Error fetching lists:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Create a new list
router.post('/communities/:communityId/lists', authenticateToken, async (req, res) => {
    try {
        const { communityId } = req.params;
        const userId = req.user.id;
        const { name, description, color, emoji } = req.body;

        // Validate input
        if (!name || name.trim().length === 0) {
            return res.status(400).json({ error: 'List name is required' });
        }

        // Verify user has admin access to this community
        const communityAccess = await pool.query(
            'SELECT role FROM collaborators WHERE user_id = $1 AND community_id = $2 AND status = $3',
            [userId, communityId, 'approved']
        );

        if (communityAccess.rows.length === 0) {
            return res.status(403).json({ error: 'Access denied to this community' });
        }

        const userRole = communityAccess.rows[0].role;
        if (!['owner', 'admin', 'limited_admin'].includes(userRole)) {
            return res.status(403).json({ error: 'Insufficient permissions to create lists' });
        }

        // Check if list name already exists in this community
        const existingList = await pool.query(
            'SELECT id FROM lists WHERE community_id = $1 AND name = $2',
            [communityId, name.trim()]
        );

        if (existingList.rows.length > 0) {
            return res.status(409).json({ error: 'A list with this name already exists' });
        }

        // Create the list
        const createListQuery = `
            INSERT INTO lists (community_id, name, description, color, emoji, created_by)
            VALUES ($1, $2, $3, $4, $5, $6)
            RETURNING *
        `;

        const result = await pool.query(createListQuery, [
            communityId,
            name.trim(),
            description?.trim() || null,
            color || '#007AFF',
            emoji || null,
            userId
        ]);

        const newList = result.rows[0];

        // Log the action
        await auditLog({
            userId,
            communityId,
            action: 'create_list',
            tableName: 'lists',
            recordId: newList.id,
            newValues: {
                name: newList.name,
                description: newList.description,
                color: newList.color,
                emoji: newList.emoji
            }
        });

        res.status(201).json({
            list: {
                id: newList.id,
                communityId: newList.community_id,
                name: newList.name,
                description: newList.description,
                color: newList.color,
                emoji: newList.emoji,
                isDefault: newList.is_default,
                createdBy: newList.created_by,
                createdAt: newList.created_at,
                updatedAt: newList.updated_at,
                memberCount: 0
            }
        });

    } catch (error) {
        console.error('Error creating list:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Update a list
router.put('/lists/:listId', authenticateToken, async (req, res) => {
    try {
        const { listId } = req.params;
        const userId = req.user.id;
        const { name, description, color, emoji } = req.body;

        // Get the list and verify access
        const listQuery = `
            SELECT l.*, c.id as community_id
            FROM lists l
            JOIN communities c ON l.community_id = c.id
            WHERE l.id = $1
        `;

        const listResult = await pool.query(listQuery, [listId]);
        
        if (listResult.rows.length === 0) {
            return res.status(404).json({ error: 'List not found' });
        }

        const list = listResult.rows[0];
        const communityId = list.community_id;

        // Verify user has admin access to this community
        const communityAccess = await pool.query(
            'SELECT role FROM collaborators WHERE user_id = $1 AND community_id = $2 AND status = $3',
            [userId, communityId, 'approved']
        );

        if (communityAccess.rows.length === 0) {
            return res.status(403).json({ error: 'Access denied to this community' });
        }

        const userRole = communityAccess.rows[0].role;
        if (!['owner', 'admin', 'limited_admin'].includes(userRole)) {
            return res.status(403).json({ error: 'Insufficient permissions to update lists' });
        }

        // Check if list name already exists (if name is being changed)
        if (name && name.trim() !== list.name) {
            const existingList = await pool.query(
                'SELECT id FROM lists WHERE community_id = $1 AND name = $2 AND id != $3',
                [communityId, name.trim(), listId]
            );

            if (existingList.rows.length > 0) {
                return res.status(409).json({ error: 'A list with this name already exists' });
            }
        }

        // Update the list
        const updateQuery = `
            UPDATE lists 
            SET name = COALESCE($1, name),
                description = COALESCE($2, description),
                color = COALESCE($3, color),
                emoji = COALESCE($4, emoji),
                updated_at = NOW()
            WHERE id = $5
            RETURNING *
        `;

        const result = await pool.query(updateQuery, [
            name?.trim() || null,
            description?.trim() || null,
            color || null,
            emoji || null,
            listId
        ]);

        const updatedList = result.rows[0];

        // Log the action
        await auditLog({
            userId,
            communityId,
            action: 'update_list',
            tableName: 'lists',
            recordId: listId,
            oldValues: {
                name: list.name,
                description: list.description,
                color: list.color,
                emoji: list.emoji
            },
            newValues: {
                name: updatedList.name,
                description: updatedList.description,
                color: updatedList.color,
                emoji: updatedList.emoji
            }
        });

        res.json({
            list: {
                id: updatedList.id,
                communityId: updatedList.community_id,
                name: updatedList.name,
                description: updatedList.description,
                color: updatedList.color,
                emoji: updatedList.emoji,
                isDefault: updatedList.is_default,
                createdBy: updatedList.created_by,
                createdAt: updatedList.created_at,
                updatedAt: updatedList.updated_at,
                memberCount: 0 // This would need to be calculated separately
            }
        });

    } catch (error) {
        console.error('Error updating list:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Delete a list
router.delete('/lists/:listId', authenticateToken, async (req, res) => {
    try {
        const { listId } = req.params;
        const userId = req.user.id;

        // Get the list and verify access
        const listQuery = `
            SELECT l.*, c.id as community_id
            FROM lists l
            JOIN communities c ON l.community_id = c.id
            WHERE l.id = $1
        `;

        const listResult = await pool.query(listQuery, [listId]);
        
        if (listResult.rows.length === 0) {
            return res.status(404).json({ error: 'List not found' });
        }

        const list = listResult.rows[0];
        const communityId = list.community_id;

        // Prevent deletion of default lists
        if (list.is_default) {
            return res.status(400).json({ error: 'Cannot delete default lists' });
        }

        // Verify user has admin access to this community
        const communityAccess = await pool.query(
            'SELECT role FROM collaborators WHERE user_id = $1 AND community_id = $2 AND status = $3',
            [userId, communityId, 'approved']
        );

        if (communityAccess.rows.length === 0) {
            return res.status(403).json({ error: 'Access denied to this community' });
        }

        const userRole = communityAccess.rows[0].role;
        if (!['owner', 'admin', 'limited_admin'].includes(userRole)) {
            return res.status(403).json({ error: 'Insufficient permissions to delete lists' });
        }

        // Delete the list (member_lists will be deleted automatically due to CASCADE)
        await pool.query('DELETE FROM lists WHERE id = $1', [listId]);

        // Log the action
        await auditLog({
            userId,
            communityId,
            action: 'delete_list',
            tableName: 'lists',
            recordId: listId,
            oldValues: {
                name: list.name,
                description: list.description,
                color: list.color,
                emoji: list.emoji
            }
        });

        res.status(204).send();

    } catch (error) {
        console.error('Error deleting list:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Add members to a list
router.post('/lists/:listId/members', authenticateToken, async (req, res) => {
    try {
        const { listId } = req.params;
        const userId = req.user.id;
        const { memberIds } = req.body;

        if (!memberIds || !Array.isArray(memberIds) || memberIds.length === 0) {
            return res.status(400).json({ error: 'Member IDs are required' });
        }

        // Get the list and verify access
        const listQuery = `
            SELECT l.*, c.id as community_id
            FROM lists l
            JOIN communities c ON l.community_id = c.id
            WHERE l.id = $1
        `;

        const listResult = await pool.query(listQuery, [listId]);
        
        if (listResult.rows.length === 0) {
            return res.status(404).json({ error: 'List not found' });
        }

        const list = listResult.rows[0];
        const communityId = list.community_id;

        // Verify user has admin access to this community
        const communityAccess = await pool.query(
            'SELECT role FROM collaborators WHERE user_id = $1 AND community_id = $2 AND status = $3',
            [userId, communityId, 'approved']
        );

        if (communityAccess.rows.length === 0) {
            return res.status(403).json({ error: 'Access denied to this community' });
        }

        const userRole = communityAccess.rows[0].role;
        if (!['owner', 'admin', 'limited_admin'].includes(userRole)) {
            return res.status(403).json({ error: 'Insufficient permissions to modify lists' });
        }

        // Verify all members belong to this community
        const membersQuery = `
            SELECT id FROM members 
            WHERE id = ANY($1) AND community_id = $2
        `;

        const membersResult = await pool.query(membersQuery, [memberIds, communityId]);
        
        if (membersResult.rows.length !== memberIds.length) {
            return res.status(400).json({ error: 'Some members do not belong to this community' });
        }

        // Add members to the list (ignore duplicates)
        const insertQuery = `
            INSERT INTO member_lists (member_id, list_id, added_by)
            SELECT unnest($1::uuid[]), $2, $3
            ON CONFLICT (member_id, list_id) DO NOTHING
        `;

        await pool.query(insertQuery, [memberIds, listId, userId]);

        // Log the action
        await auditLog({
            userId,
            communityId,
            action: 'add_members_to_list',
            tableName: 'member_lists',
            recordId: listId,
            newValues: {
                memberIds,
                listId
            }
        });

        res.status(200).json({ message: 'Members added to list successfully' });

    } catch (error) {
        console.error('Error adding members to list:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Remove members from a list
router.delete('/lists/:listId/members', authenticateToken, async (req, res) => {
    try {
        const { listId } = req.params;
        const userId = req.user.id;
        const { memberIds } = req.body;

        if (!memberIds || !Array.isArray(memberIds) || memberIds.length === 0) {
            return res.status(400).json({ error: 'Member IDs are required' });
        }

        // Get the list and verify access
        const listQuery = `
            SELECT l.*, c.id as community_id
            FROM lists l
            JOIN communities c ON l.community_id = c.id
            WHERE l.id = $1
        `;

        const listResult = await pool.query(listQuery, [listId]);
        
        if (listResult.rows.length === 0) {
            return res.status(404).json({ error: 'List not found' });
        }

        const list = listResult.rows[0];
        const communityId = list.community_id;

        // Verify user has admin access to this community
        const communityAccess = await pool.query(
            'SELECT role FROM collaborators WHERE user_id = $1 AND community_id = $2 AND status = $3',
            [userId, communityId, 'approved']
        );

        if (communityAccess.rows.length === 0) {
            return res.status(403).json({ error: 'Access denied to this community' });
        }

        const userRole = communityAccess.rows[0].role;
        if (!['owner', 'admin', 'limited_admin'].includes(userRole)) {
            return res.status(403).json({ error: 'Insufficient permissions to modify lists' });
        }

        // Remove members from the list
        const deleteQuery = `
            DELETE FROM member_lists 
            WHERE list_id = $1 AND member_id = ANY($2::uuid[])
        `;

        await pool.query(deleteQuery, [listId, memberIds]);

        // Log the action
        await auditLog({
            userId,
            communityId,
            action: 'remove_members_from_list',
            tableName: 'member_lists',
            recordId: listId,
            oldValues: {
                memberIds,
                listId
            }
        });

        res.status(200).json({ message: 'Members removed from list successfully' });

    } catch (error) {
        console.error('Error removing members from list:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Get members in a specific list
router.get('/lists/:listId/members', authenticateToken, async (req, res) => {
    try {
        const { listId } = req.params;
        const userId = req.user.id;

        // Get the list and verify access
        const listQuery = `
            SELECT l.*, c.id as community_id
            FROM lists l
            JOIN communities c ON l.community_id = c.id
            WHERE l.id = $1
        `;

        const listResult = await pool.query(listQuery, [listId]);
        
        if (listResult.rows.length === 0) {
            return res.status(404).json({ error: 'List not found' });
        }

        const list = listResult.rows[0];
        const communityId = list.community_id;

        // Verify user has access to this community
        const communityAccess = await pool.query(
            'SELECT role FROM collaborators WHERE user_id = $1 AND community_id = $2 AND status = $3',
            [userId, communityId, 'approved']
        );

        if (communityAccess.rows.length === 0) {
            return res.status(403).json({ error: 'Access denied to this community' });
        }

        // Get members in this list
        const membersQuery = `
            SELECT m.*, ml.added_at
            FROM members m
            JOIN member_lists ml ON m.id = ml.member_id
            WHERE ml.list_id = $1
            ORDER BY m.first_name, m.last_name
        `;

        const result = await pool.query(membersQuery, [listId]);
        
        res.json({
            list: {
                id: list.id,
                name: list.name,
                description: list.description,
                color: list.color,
                emoji: list.emoji
            },
            members: result.rows.map(row => ({
                id: row.id,
                firstName: row.first_name,
                lastName: row.last_name,
                email: row.email,
                phoneNumber: row.phone_number,
                address: row.address,
                city: row.city,
                state: row.state,
                zip: row.zip,
                country: row.country,
                dateOfBirth: row.date_of_birth,
                membershipDate: row.membership_date,
                status: row.status,
                notes: row.notes,
                addedToListAt: row.added_at
            }))
        });

    } catch (error) {
        console.error('Error fetching list members:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

module.exports = router;
