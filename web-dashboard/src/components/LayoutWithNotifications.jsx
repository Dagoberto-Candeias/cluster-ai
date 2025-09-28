import React, { useState, useEffect } from 'react';
import { Box, Snackbar, Alert } from '@mui/material';
import Layout from './Layout';

const LayoutWithNotifications = ({ children }) => {
  const [notifications, setNotifications] = useState([]);
  const [open, setOpen] = useState(false);
  const [currentNotification, setCurrentNotification] = useState(null);

  useEffect(() => {
    // Example: subscribe to notification events (e.g., WebSocket or context)
    // For demo, simulate a notification after 5 seconds
    const timer = setTimeout(() => {
      const newNotification = {
        id: Date.now(),
        message: 'New alert received!',
        severity: 'warning'
      };
      setNotifications(prev => [...prev, newNotification]);
      setCurrentNotification(newNotification);
      setOpen(true);
    }, 5000);

    return () => clearTimeout(timer);
  }, []);

  const handleClose = (event, reason) => {
    if (reason === 'clickaway') {
      return;
    }
    setOpen(false);
  };

  return (
    <Layout>
      <Box sx={{ minHeight: '100vh' }}>
        {children}
        {currentNotification && (
          <Snackbar
            open={open}
            autoHideDuration={6000}
            onClose={handleClose}
            anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
          >
            <Alert onClose={handleClose} severity={currentNotification.severity} sx={{ width: '100%' }}>
              {currentNotification.message}
            </Alert>
          </Snackbar>
        )}
      </Box>
    </Layout>
  );
};

export default LayoutWithNotifications;
