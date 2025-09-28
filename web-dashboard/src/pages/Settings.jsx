import React, { useState, useEffect } from 'react';
import {
  Typography,
  Box,
  Paper,
  Grid,
  TextField,
  Button,
  Switch,
  FormControlLabel,
  Divider,
  Alert,
  Card,
  CardContent,
  Slider,
  InputAdornment,
  useTheme
} from '@mui/material';
import {
  Save as SaveIcon,
  Refresh as RefreshIcon,
  Settings as SettingsIcon,
  Notifications as NotificationsIcon,
  Security as SecurityIcon
} from '@mui/icons-material';
import axios from 'axios';

function Settings() {
  const theme = useTheme();
  const [settings, setSettings] = useState({
    // Monitoring settings
    monitoring_enabled: true,
    update_interval: 5,
    alert_threshold_cpu: 80,
    alert_threshold_memory: 80,
    alert_threshold_disk: 90,

    // Notification settings
    email_notifications: false,
    slack_notifications: false,
    notification_email: '',

    // Security settings
    session_timeout: 30,
    max_login_attempts: 5,

    // System settings
    log_level: 'INFO',
    backup_enabled: true,
    backup_interval: 24
  });

  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState(null);

  useEffect(() => {
    fetchSettings();
  }, []);

  const fetchSettings = async () => {
    setLoading(true);
    try {
      const response = await axios.get('/api/settings');
      if (response.data) {
        setSettings(prev => ({ ...prev, ...response.data }));
      }
    } catch (error) {
      console.error('Failed to fetch settings:', error);
      // Use default settings if API fails
    } finally {
      setLoading(false);
    }
  };

  const saveSettings = async () => {
    setSaving(true);
    setMessage(null);
    try {
      await axios.post('/api/settings', settings);
      setMessage({ type: 'success', text: 'Configurações salvas com sucesso!' });
    } catch (error) {
      console.error('Failed to save settings:', error);
      setMessage({ type: 'error', text: 'Erro ao salvar configurações.' });
    } finally {
      setSaving(false);
    }
  };

  const handleSettingChange = (key, value) => {
    setSettings(prev => ({ ...prev, [key]: value }));
  };

  const resetToDefaults = () => {
    setSettings({
      monitoring_enabled: true,
      update_interval: 5,
      alert_threshold_cpu: 80,
      alert_threshold_memory: 80,
      alert_threshold_disk: 90,
      email_notifications: false,
      slack_notifications: false,
      notification_email: '',
      session_timeout: 30,
      max_login_attempts: 5,
      log_level: 'INFO',
      backup_enabled: true,
      backup_interval: 24
    });
    setMessage({ type: 'info', text: 'Configurações resetadas para padrão.' });
  };

  return (
    <Box p={3}>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4" component="h1" sx={{ display: 'flex', alignItems: 'center' }}>
          <SettingsIcon sx={{ mr: 2 }} />
          Configurações do Sistema
        </Typography>
        <Box display="flex" gap={2}>
          <Button
            variant="outlined"
            startIcon={<RefreshIcon />}
            onClick={fetchSettings}
            disabled={loading}
          >
            Recarregar
          </Button>
          <Button
            variant="contained"
            startIcon={<SaveIcon />}
            onClick={saveSettings}
            disabled={saving}
          >
            {saving ? 'Salvando...' : 'Salvar'}
          </Button>
        </Box>
      </Box>

      {message && (
        <Alert severity={message.type} sx={{ mb: 3 }}>
          {message.text}
        </Alert>
      )}

      <Grid container spacing={3}>
        {/* Monitoring Settings */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center' }}>
                <SettingsIcon sx={{ mr: 1 }} />
                Monitoramento
              </Typography>
              <Box display="flex" flexDirection="column" gap={3}>
                <FormControlLabel
                  control={
                    <Switch
                      checked={settings.monitoring_enabled}
                      onChange={(e) => handleSettingChange('monitoring_enabled', e.target.checked)}
                    />
                  }
                  label="Monitoramento habilitado"
                />

                <Box>
                  <Typography variant="body2" gutterBottom>
                    Intervalo de atualização (segundos): {settings.update_interval}
                  </Typography>
                  <Slider
                    value={settings.update_interval}
                    onChange={(e, value) => handleSettingChange('update_interval', value)}
                    min={1}
                    max={60}
                    step={1}
                    marks
                    valueLabelDisplay="auto"
                  />
                </Box>

                <Divider />

                <Typography variant="subtitle2" gutterBottom>
                  Limites de alerta (%)
                </Typography>

                <Box>
                  <Typography variant="body2" gutterBottom>
                    CPU: {settings.alert_threshold_cpu}%
                  </Typography>
                  <Slider
                    value={settings.alert_threshold_cpu}
                    onChange={(e, value) => handleSettingChange('alert_threshold_cpu', value)}
                    min={50}
                    max={100}
                    step={5}
                    valueLabelDisplay="auto"
                  />
                </Box>

                <Box>
                  <Typography variant="body2" gutterBottom>
                    Memória: {settings.alert_threshold_memory}%
                  </Typography>
                  <Slider
                    value={settings.alert_threshold_memory}
                    onChange={(e, value) => handleSettingChange('alert_threshold_memory', value)}
                    min={50}
                    max={100}
                    step={5}
                    valueLabelDisplay="auto"
                  />
                </Box>

                <Box>
                  <Typography variant="body2" gutterBottom>
                    Disco: {settings.alert_threshold_disk}%
                  </Typography>
                  <Slider
                    value={settings.alert_threshold_disk}
                    onChange={(e, value) => handleSettingChange('alert_threshold_disk', value)}
                    min={70}
                    max={100}
                    step={5}
                    valueLabelDisplay="auto"
                  />
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Notification Settings */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center' }}>
                <NotificationsIcon sx={{ mr: 1 }} />
                Notificações
              </Typography>
              <Box display="flex" flexDirection="column" gap={3}>
                <FormControlLabel
                  control={
                    <Switch
                      checked={settings.email_notifications}
                      onChange={(e) => handleSettingChange('email_notifications', e.target.checked)}
                    />
                  }
                  label="Notificações por email"
                />

                {settings.email_notifications && (
                  <TextField
                    label="Email para notificações"
                    type="email"
                    value={settings.notification_email}
                    onChange={(e) => handleSettingChange('notification_email', e.target.value)}
                    fullWidth
                    variant="outlined"
                  />
                )}

                <FormControlLabel
                  control={
                    <Switch
                      checked={settings.slack_notifications}
                      onChange={(e) => handleSettingChange('slack_notifications', e.target.checked)}
                    />
                  }
                  label="Notificações Slack"
                />
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Security Settings */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center' }}>
                <SecurityIcon sx={{ mr: 1 }} />
                Segurança
              </Typography>
              <Box display="flex" flexDirection="column" gap={3}>
                <TextField
                  label="Timeout da sessão (minutos)"
                  type="number"
                  value={settings.session_timeout}
                  onChange={(e) => handleSettingChange('session_timeout', parseInt(e.target.value))}
                  InputProps={{
                    endAdornment: <InputAdornment position="end">min</InputAdornment>,
                  }}
                  fullWidth
                  variant="outlined"
                />

                <TextField
                  label="Máximo de tentativas de login"
                  type="number"
                  value={settings.max_login_attempts}
                  onChange={(e) => handleSettingChange('max_login_attempts', parseInt(e.target.value))}
                  fullWidth
                  variant="outlined"
                />
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* System Settings */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center' }}>
                <SettingsIcon sx={{ mr: 1 }} />
                Sistema
              </Typography>
              <Box display="flex" flexDirection="column" gap={3}>
                <TextField
                  select
                  label="Nível de log"
                  value={settings.log_level}
                  onChange={(e) => handleSettingChange('log_level', e.target.value)}
                  fullWidth
                  variant="outlined"
                >
                  <option value="DEBUG">Debug</option>
                  <option value="INFO">Info</option>
                  <option value="WARNING">Warning</option>
                  <option value="ERROR">Error</option>
                  <option value="CRITICAL">Critical</option>
                </TextField>

                <FormControlLabel
                  control={
                    <Switch
                      checked={settings.backup_enabled}
                      onChange={(e) => handleSettingChange('backup_enabled', e.target.checked)}
                    />
                  }
                  label="Backup automático habilitado"
                />

                {settings.backup_enabled && (
                  <TextField
                    label="Intervalo de backup (horas)"
                    type="number"
                    value={settings.backup_interval}
                    onChange={(e) => handleSettingChange('backup_interval', parseInt(e.target.value))}
                    InputProps={{
                      endAdornment: <InputAdornment position="end">h</InputAdornment>,
                    }}
                    fullWidth
                    variant="outlined"
                  />
                )}
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Reset Button */}
      <Box mt={4} display="flex" justifyContent="center">
        <Button
          variant="outlined"
          color="secondary"
          onClick={resetToDefaults}
          sx={{ minWidth: 200 }}
        >
          Resetar para Padrão
        </Button>
      </Box>
    </Box>
  );
}

export default Settings;
