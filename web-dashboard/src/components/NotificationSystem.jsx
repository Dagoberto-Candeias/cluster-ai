import React, { useState, useEffect } from 'react';
import { Snackbar, Alert, IconButton, Badge, Menu, MenuItem, Typography, Box, Chip } from '@mui/material';
import NotificationsIcon from '@mui/icons-material/Notifications';
import CloseIcon from '@mui/icons-material/Close';
import axios from 'axios';

const NotificationSystem = () => {
  const [notifications, setNotifications] = useState([]);
  const [openSnackbar, setOpenSnackbar] = useState(false);
  const [currentNotification, setCurrentNotification] = useState(null);
  const [anchorEl, setAnchorEl] = useState(null);
  const [unreadCount, setUnreadCount] = useState(0);

  const fetchAlerts = async () => {
    try {
      const response = await axios.get('/api/alerts?limit=10');
      const newAlerts = response.data;

      // Check for new alerts
      const existingIds = notifications.map(n => n.id);
      const newNotifications = newAlerts.filter(alert => !existingIds.includes(generateAlertId(alert)));

      if (newNotifications.length > 0) {
        const formattedNotifications = newNotifications.map(alert => ({
          id: generateAlertId(alert),
          type: getAlertType(alert.severity),
          title: getAlertTitle(alert),
          message: alert.message,
          timestamp: new Date(alert.timestamp),
          severity: alert.severity,
          component: alert.component,
          read: false
        }));

        setNotifications(prev => [...formattedNotifications, ...prev].slice(0, 50)); // Keep last 50

        // Show snackbar for critical alerts
        const criticalAlert = formattedNotifications.find(n => n.severity === 'CRITICAL');
        if (criticalAlert) {
          setCurrentNotification(criticalAlert);
          setOpenSnackbar(true);
        }

        updateUnreadCount();
      }
    } catch (error) {
      console.error('Failed to fetch alerts:', error);
    }
  };

  const generateAlertId = (alert) => {
    return `${alert.timestamp}-${alert.severity}-${alert.component}`;
  };

  const getAlertType = (severity) => {
    switch (severity.toLowerCase()) {
      case 'critical': return 'error';
      case 'warning': return 'warning';
      case 'info': return 'info';
      default: return 'info';
    }
  };

  const getAlertTitle = (alert) => {
    const component = alert.component || 'SYSTEM';
    switch (alert.severity.toLowerCase()) {
      case 'critical':
        return `🚨 ${component} - Crítico`;
      case 'warning':
        return `⚠️ ${component} - Aviso`;
      case 'info':
        return `ℹ️ ${component} - Informação`;
      default:
        return `${component} - Alerta`;
    }
  };

  const updateUnreadCount = () => {
    const unread = notifications.filter(n => !n.read).length;
    setUnreadCount(unread);
  };

  const handleNotificationClick = (event) => {
    setAnchorEl(event.currentTarget);
  };

  const handleNotificationClose = () => {
    setAnchorEl(null);
  };

  const handleNotificationItemClick = (notification) => {
    // Mark as read
    setNotifications(prev =>
      prev.map(n => n.id === notification.id ? { ...n, read: true } : n)
    );
    updateUnreadCount();
    setAnchorEl(null);
  };

  const handleSnackbarClose = (event, reason) => {
    if (reason === 'clickaway') {
      return;
    }
    setOpenSnackbar(false);
  };

  const clearAllNotifications = () => {
    setNotifications([]);
    setUnreadCount(0);
    setAnchorEl(null);
  };

  const markAllAsRead = () => {
    setNotifications(prev => prev.map(n => ({ ...n, read: true })));
    setUnreadCount(0);
  };

  useEffect(() => {
    fetchAlerts();
    const interval = setInterval(fetchAlerts, 30000); // Check every 30 seconds
    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    updateUnreadCount();
  }, [notifications]);

  return (
    <>
      <IconButton
        color="inherit"
        onClick={handleNotificationClick}
        sx={{ mr: 1 }}
      >
        <Badge badgeContent={unreadCount} color="error">
          <NotificationsIcon />
        </Badge>
      </IconButton>

      <Menu
        anchorEl={anchorEl}
        open={Boolean(anchorEl)}
        onClose={handleNotificationClose}
        PaperProps={{
          sx: { width: 400, maxHeight: 500 }
        }}
      >
        <Box sx={{ p: 2, borderBottom: '1px solid #e0e0e0' }}>
          <Typography variant="h6">Notificações</Typography>
          <Box sx={{ mt: 1, display: 'flex', gap: 1 }}>
            <Chip
              label={`Não lidas: ${unreadCount}`}
              size="small"
              color={unreadCount > 0 ? 'error' : 'default'}
            />
            <Chip
              label={`Total: ${notifications.length}`}
              size="small"
              variant="outlined"
            />
          </Box>
        </Box>

        {notifications.length === 0 ? (
          <MenuItem disabled>
            <Typography variant="body2" color="text.secondary">
              Nenhuma notificação
            </Typography>
          </MenuItem>
        ) : (
          <>
            {notifications.slice(0, 10).map((notification) => (
              <MenuItem
                key={notification.id}
                onClick={() => handleNotificationItemClick(notification)}
                sx={{
                  backgroundColor: notification.read ? 'transparent' : 'rgba(25, 118, 210, 0.08)',
                  borderLeft: `4px solid ${notification.severity === 'CRITICAL' ? '#f44336' :
                    notification.severity === 'WARNING' ? '#ff9800' : '#2196f3'}`
                }}
              >
                <Box sx={{ width: '100%' }}>
                  <Typography variant="subtitle2" sx={{ fontWeight: notification.read ? 'normal' : 'bold' }}>
                    {notification.title}
                  </Typography>
                  <Typography variant="body2" color="text.secondary" sx={{ mt: 0.5 }}>
                    {notification.message.length > 100
                      ? `${notification.message.substring(0, 100)}...`
                      : notification.message}
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    {notification.timestamp.toLocaleString()}
                  </Typography>
                </Box>
              </MenuItem>
            ))}

            <Box sx={{ p: 1, borderTop: '1px solid #e0e0e0', display: 'flex', justifyContent: 'space-between' }}>
              <Typography
                variant="body2"
                color="primary"
                sx={{ cursor: 'pointer' }}
                onClick={markAllAsRead}
              >
                Marcar todas como lidas
              </Typography>
              <Typography
                variant="body2"
                color="error"
                sx={{ cursor: 'pointer' }}
                onClick={clearAllNotifications}
              >
                Limpar todas
              </Typography>
            </Box>
          </>
        )}
      </Menu>

      <Snackbar
        open={openSnackbar}
        autoHideDuration={10000}
        onClose={handleSnackbarClose}
        anchorOrigin={{ vertical: 'top', horizontal: 'right' }}
      >
        <Alert
          onClose={handleSnackbarClose}
          severity={currentNotification?.type || 'info'}
          sx={{ width: '100%' }}
          action={
            <IconButton
              size="small"
              aria-label="close"
              color="inherit"
              onClick={handleSnackbarClose}
            >
              <CloseIcon fontSize="small" />
            </IconButton>
          }
        >
          <Typography variant="subtitle2">
            {currentNotification?.title}
          </Typography>
          <Typography variant="body2">
            {currentNotification?.message}
          </Typography>
        </Alert>
      </Snackbar>
    </>
  );
};

export default NotificationSystem;
