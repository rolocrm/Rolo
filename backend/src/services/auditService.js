const { query } = require('../database/connection');

/**
 * Create an audit log entry
 * @param {Object} params - Audit log parameters
 * @param {string} params.userId - ID of the user performing the action
 * @param {string} params.communityId - ID of the community (optional)
 * @param {string} params.action - Action being performed
 * @param {string} params.tableName - Name of the table being affected
 * @param {string} params.recordId - ID of the record being affected
 * @param {Object} params.oldValues - Previous values (optional)
 * @param {Object} params.newValues - New values (optional)
 * @param {string} params.ipAddress - IP address of the request (optional)
 * @param {string} params.userAgent - User agent string (optional)
 */
const createAuditLog = async (params) => {
  try {
    const {
      userId,
      communityId,
      action,
      tableName,
      recordId,
      oldValues,
      newValues,
      ipAddress,
      userAgent
    } = params;

    // Validate required parameters
    if (!userId || !action || !tableName) {
      console.warn('Missing required audit log parameters:', params);
      return;
    }

    const result = await query(
      `INSERT INTO audit_logs (
        user_id, 
        community_id, 
        action, 
        table_name, 
        record_id, 
        old_values, 
        new_values, 
        ip_address, 
        user_agent
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING id`,
      [
        userId,
        communityId || null,
        action,
        tableName,
        recordId || null,
        oldValues ? JSON.stringify(oldValues) : null,
        newValues ? JSON.stringify(newValues) : null,
        ipAddress || null,
        userAgent || null
      ]
    );

    console.log(`📝 Audit log created: ${action} on ${tableName}`, result.rows[0].id);
    return result.rows[0];
  } catch (error) {
    console.error('❌ Failed to create audit log:', error);
    // Don't throw error to avoid breaking main functionality
  }
};

/**
 * Get audit logs for a specific user
 * @param {string} userId - User ID
 * @param {number} limit - Maximum number of logs to return
 * @param {number} offset - Number of logs to skip
 */
const getUserAuditLogs = async (userId, limit = 50, offset = 0) => {
  try {
    const result = await query(
      `SELECT * FROM audit_logs 
       WHERE user_id = $1 
       ORDER BY created_at DESC 
       LIMIT $2 OFFSET $3`,
      [userId, limit, offset]
    );

    return result.rows;
  } catch (error) {
    console.error('❌ Failed to get user audit logs:', error);
    throw error;
  }
};

/**
 * Get audit logs for a specific community
 * @param {string} communityId - Community ID
 * @param {number} limit - Maximum number of logs to return
 * @param {number} offset - Number of logs to skip
 */
const getCommunityAuditLogs = async (communityId, limit = 50, offset = 0) => {
  try {
    const result = await query(
      `SELECT al.*, 
              up.first_name, 
              up.last_name,
              u.email
       FROM audit_logs al
       JOIN users u ON al.user_id = u.id
       JOIN user_profiles up ON u.id = up.user_id
       WHERE al.community_id = $1 
       ORDER BY al.created_at DESC 
       LIMIT $2 OFFSET $3`,
      [communityId, limit, offset]
    );

    return result.rows;
  } catch (error) {
    console.error('❌ Failed to get community audit logs:', error);
    throw error;
  }
};

/**
 * Get audit logs for a specific record
 * @param {string} tableName - Name of the table
 * @param {string} recordId - ID of the record
 * @param {number} limit - Maximum number of logs to return
 * @param {number} offset - Number of logs to skip
 */
const getRecordAuditLogs = async (tableName, recordId, limit = 50, offset = 0) => {
  try {
    const result = await query(
      `SELECT al.*, 
              up.first_name, 
              up.last_name,
              u.email
       FROM audit_logs al
       JOIN users u ON al.user_id = u.id
       JOIN user_profiles up ON u.id = up.user_id
       WHERE al.table_name = $1 AND al.record_id = $2
       ORDER BY al.created_at DESC 
       LIMIT $3 OFFSET $4`,
      [tableName, recordId, limit, offset]
    );

    return result.rows;
  } catch (error) {
    console.error('❌ Failed to get record audit logs:', error);
    throw error;
  }
};

/**
 * Get audit logs by action type
 * @param {string} action - Action type to filter by
 * @param {number} limit - Maximum number of logs to return
 * @param {number} offset - Number of logs to skip
 */
const getAuditLogsByAction = async (action, limit = 50, offset = 0) => {
  try {
    const result = await query(
      `SELECT al.*, 
              up.first_name, 
              up.last_name,
              u.email
       FROM audit_logs al
       JOIN users u ON al.user_id = u.id
       JOIN user_profiles up ON u.id = up.user_id
       WHERE al.action = $1
       ORDER BY al.created_at DESC 
       LIMIT $2 OFFSET $3`,
      [action, limit, offset]
    );

    return result.rows;
  } catch (error) {
    console.error('❌ Failed to get audit logs by action:', error);
    throw error;
  }
};

/**
 * Get audit logs within a date range
 * @param {Date} startDate - Start date
 * @param {Date} endDate - End date
 * @param {number} limit - Maximum number of logs to return
 * @param {number} offset - Number of logs to skip
 */
const getAuditLogsByDateRange = async (startDate, endDate, limit = 50, offset = 0) => {
  try {
    const result = await query(
      `SELECT al.*, 
              up.first_name, 
              up.last_name,
              u.email
       FROM audit_logs al
       JOIN users u ON al.user_id = u.id
       JOIN user_profiles up ON u.id = up.user_id
       WHERE al.created_at >= $1 AND al.created_at <= $2
       ORDER BY al.created_at DESC 
       LIMIT $3 OFFSET $4`,
      [startDate, endDate, limit, offset]
    );

    return result.rows;
  } catch (error) {
    console.error('❌ Failed to get audit logs by date range:', error);
    throw error;
  }
};

/**
 * Clean up old audit logs (older than specified days)
 * @param {number} daysOld - Number of days old to consider for cleanup
 */
const cleanupOldAuditLogs = async (daysOld = 365) => {
  try {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - daysOld);

    const result = await query(
      'DELETE FROM audit_logs WHERE created_at < $1 RETURNING id',
      [cutoffDate]
    );

    console.log(`🧹 Cleaned up ${result.rows.length} old audit logs`);
    return result.rows.length;
  } catch (error) {
    console.error('❌ Failed to cleanup old audit logs:', error);
    throw error;
  }
};

module.exports = {
  createAuditLog,
  getUserAuditLogs,
  getCommunityAuditLogs,
  getRecordAuditLogs,
  getAuditLogsByAction,
  getAuditLogsByDateRange,
  cleanupOldAuditLogs
};
