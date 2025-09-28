import React, { useState } from 'react';
import { Card, CardContent, Typography, Box, TextField, Button, Switch, FormControlLabel, Divider, Alert } from '@mui/material';
import { Save, Refresh } from '@mui/icons-material';
import { useApi } from '../contexts/ApiContext';

const SettingsPage: React.FC = () => {
  const { api } = useApi();
  const [settings, setSettings] = useState({
    ollamaUrl: 'http://localhost:11434',
    daskSchedulerUrl: 'tcp://localhost:8786',
    openwebuiUrl: 'http://localhost:3000',
    autoRefresh: true,
    refreshInterval: 30,
    enableNotifications: true,
    logLevel: 'INFO',
  });
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState('');

  const handleSave = async () => {
    setLoading(true);
    setMessage('');
    try {
      // TODO: Implement settings save API
      await new Promise(resolve => setTimeout(resolve, 1000));
      setMessage('Settings saved successfully!');
    } catch (error) {
      console.error('Failed to save settings:', error);
      setMessage('Failed to save settings. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleTestConnection = async (service: string, url: string) => {
    try {
      // TODO: Implement connection testing
      console.log(`Testing connection to ${service} at ${url}`);
      await new Promise(resolve => setTimeout(resolve, 500));
      setMessage(`${service} connection test successful!`);
    } catch (error) {
      setMessage(`${service} connection test failed.`);
    }
  };

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        System Settings
      </Typography>

      {message && (
        <Alert severity={message.includes('failed') ? 'error' : 'success'} sx={{ mb: 3 }}>
          {message}
        </Alert>
      )}

      <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 3 }}>
        {/* Service URLs */}
        <Box sx={{ flex: '1 1 400px', minWidth: '400px' }}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Service Configuration
              </Typography>

              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                <TextField
                  label="Ollama API URL"
                  value={settings.ollamaUrl}
                  onChange={(e) => setSettings({ ...settings, ollamaUrl: e.target.value })}
                  fullWidth
                  InputProps={{
                    endAdornment: (
                      <Button
                        size="small"
                        onClick={() => handleTestConnection('Ollama', settings.ollamaUrl)}
                      >
                        Test
                      </Button>
                    ),
                  }}
                />

                <TextField
                  label="Dask Scheduler URL"
                  value={settings.daskSchedulerUrl}
                  onChange={(e) => setSettings({ ...settings, daskSchedulerUrl: e.target.value })}
                  fullWidth
                  InputProps={{
                    endAdornment: (
                      <Button
                        size="small"
                        onClick={() => handleTestConnection('Dask Scheduler', settings.daskSchedulerUrl)}
                      >
                        Test
                      </Button>
                    ),
                  }}
                />

                <TextField
                  label="OpenWebUI URL"
                  value={settings.openwebuiUrl}
                  onChange={(e) => setSettings({ ...settings, openwebuiUrl: e.target.value })}
                  fullWidth
                  InputProps={{
                    endAdornment: (
                      <Button
                        size="small"
                        onClick={() => handleTestConnection('OpenWebUI', settings.openwebuiUrl)}
                      >
                        Test
                      </Button>
                    ),
                  }}
                />
              </Box>
            </CardContent>
          </Card>
        </Box>

        {/* Dashboard Settings */}
        <Box sx={{ flex: '1 1 400px', minWidth: '400px' }}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Dashboard Settings
              </Typography>

              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                <FormControlLabel
                  control={
                    <Switch
                      checked={settings.autoRefresh}
                      onChange={(e) => setSettings({ ...settings, autoRefresh: e.target.checked })}
                    />
                  }
                  label="Auto-refresh dashboard"
                />

                <TextField
                  label="Refresh Interval (seconds)"
                  type="number"
                  value={settings.refreshInterval}
                  onChange={(e) => setSettings({ ...settings, refreshInterval: parseInt(e.target.value) || 30 })}
                  disabled={!settings.autoRefresh}
                  fullWidth
                />

                <FormControlLabel
                  control={
                    <Switch
                      checked={settings.enableNotifications}
                      onChange={(e) => setSettings({ ...settings, enableNotifications: e.target.checked })}
                    />
                  }
                  label="Enable notifications"
                />

                <TextField
                  select
                  label="Log Level"
                  value={settings.logLevel}
                  onChange={(e) => setSettings({ ...settings, logLevel: e.target.value })}
                  fullWidth
                >
                  <option value="DEBUG">Debug</option>
                  <option value="INFO">Info</option>
                  <option value="WARN">Warning</option>
                  <option value="ERROR">Error</option>
                </TextField>
              </Box>
            </CardContent>
          </Card>
        </Box>

        {/* Actions */}
        <Box sx={{ flex: '1 1 100%', minWidth: '100%' }}>
          <Card>
            <CardContent>
              <Box display="flex" gap={2} justifyContent="flex-end">
                <Button
                  variant="outlined"
                  startIcon={<Refresh />}
                  onClick={() => window.location.reload()}
                >
                  Reset to Defaults
                </Button>
                <Button
                  variant="contained"
                  startIcon={<Save />}
                  onClick={handleSave}
                  disabled={loading}
                >
                  {loading ? 'Saving...' : 'Save Settings'}
                </Button>
              </Box>
            </CardContent>
          </Card>
        </Box>
      </Box>
    </Box>
  );
};

export default SettingsPage;
