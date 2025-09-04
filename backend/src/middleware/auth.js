const jwt = require('jsonwebtoken');
const { query } = require('../database/connection');

const authenticateToken = async (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Verify user still exists in database
    const userResult = await query(
      'SELECT id, email, email_verified FROM users WHERE id = $1',
      [decoded.userId]
    );

    if (userResult.rows.length === 0) {
      return res.status(401).json({ error: 'User not found' });
    }

    if (!userResult.rows[0].email_verified) {
      return res.status(403).json({ error: 'Email not verified' });
    }

    // Add user info to request
    req.user = {
      id: decoded.userId,
      email: decoded.email
    };

    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Token expired' });
    }
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({ error: 'Invalid token' });
    }
    
    console.error('Token verification error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

const requireRole = (requiredRoles) => {
  return async (req, res, next) => {
    try {
      const { communityId } = req.params;
      
      if (!communityId) {
        return res.status(400).json({ error: 'Community ID required' });
      }

      // Check user's role in the community
      const roleResult = await query(
        `SELECT role FROM collaborators 
         WHERE user_id = $1 AND community_id = $2 AND status = 'approved'`,
        [req.user.id, communityId]
      );

      if (roleResult.rows.length === 0) {
        return res.status(403).json({ error: 'Access denied to community' });
      }

      const userRole = roleResult.rows[0].role;
      
      if (!requiredRoles.includes(userRole)) {
        return res.status(403).json({ 
          error: 'Insufficient permissions',
          required: requiredRoles,
          current: userRole
        });
      }

      req.userRole = userRole;
      next();
    } catch (error) {
      console.error('Role verification error:', error);
      return res.status(500).json({ error: 'Internal server error' });
    }
  };
};

const requireOwnerOrAdmin = requireRole(['owner', 'admin']);
const requireOwner = requireRole(['owner']);
const requireAdminOrHigher = requireRole(['owner', 'admin']);

module.exports = {
  authenticateToken,
  requireRole,
  requireOwnerOrAdmin,
  requireOwner,
  requireAdminOrHigher
};
