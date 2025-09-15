import React, { useEffect, useState, useRef } from 'react';
import {
  Typography,
  Box,
  Paper,
  Grid,
  Button,
  Chip,
  CircularProgress,
  Snackbar,
  Alert,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogContentText,
  DialogActions,
} from '@mui/material';
import axios from 'axios';

function Workers() {
  const [workers, setWorkers] = useState([]);
  const [loading, setLoading] = useState(false);
  const [actionLoading, setActionLoading] = useState(null);
  const [error, setError] = useState(null);
  const [successMsg, setSuccessMsg] = useState(null);
  const [confirmDialog, setConfirmDialog] = useState({ open: false, workerId: null, action: null });
  const wsRef = useRef(null);

  const fetchWorkers = async () => {
    setLoading(true);
    try {
      const response = await axios.get('/api/workers');
      setWorkers(response.data);
    } catch (err) {
      setError('Erro ao buscar lista de workers.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchWorkers();

    // Setup WebSocket for real-time updates
    const clientId = `workers-${Date.now()}`;
    const wsUrl = `ws://localhost:8000/ws/${clientId}`;
    wsRef.current = new WebSocket(wsUrl);

    wsRef.current.onopen = () => {
      console.log('Workers WebSocket connected');
    };

    wsRef.current.onmessage = (event) => {
      try {
        const message = JSON.parse(event.data);
        if (message.type === 'realtime_update') {
          // Refresh workers list on update
          fetchWorkers();
        }
      } catch (e) {
        console.error('Failed to parse WebSocket message:', e);
      }
    };

    wsRef.current.onclose = () => {
      console.log('Workers WebSocket disconnected');
    };

    wsRef.current.onerror = (error) => {
      console.error('Workers WebSocket error:', error);
    };

    return () => {
      if (wsRef.current) {
        wsRef.current.close();
      }
    };
  }, []);

  const handleAction = (workerId, action) => {
    setConfirmDialog({ open: true, workerId, action });
  };

  const confirmAction = async () => {
    const { workerId, action } = confirmDialog;
    setConfirmDialog({ open: false, workerId: null, action: null });
    setActionLoading(workerId);
    setError(null);
    setSuccessMsg(null);

    try {
      const response = await axios.post(`/api/workers/${workerId}/${action}`);
      setSuccessMsg(response.data.message);
      fetchWorkers();
    } catch (err) {
      setError(`Falha ao executar ação ${action} no worker ${workerId}.`);
    } finally {
      setActionLoading(null);
    }
  };

  const cancelAction = () => {
    setConfirmDialog({ open: false, workerId: null, action: null });
  };

  return (
    <Box p={3}>
      <Typography variant="h4" gutterBottom>
        Gerenciamento de Workers
      </Typography>

      {loading ? (
        <Box display="flex" justifyContent="center" mt={4}>
          <CircularProgress />
        </Box>
      ) : (
        <Grid container spacing={3}>
          {workers.map((worker) => (
            <Grid item xs={12} sm={6} md={4} key={worker.id}>
              <Paper sx={{ p: 2 }}>
                <Typography variant="h6">{worker.name}</Typography>
                <Typography variant="body2" color="text.secondary">
                  Status: <Chip label={worker.status} color={worker.status === 'active' ? 'success' : 'default'} size="small" />
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  IP: {worker.ip_address}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  CPU: {worker.cpu_usage.toFixed(1)}%
                </Typography>
                <Typography variant="body2" color="text.secondary" gutterBottom>
                  Memória: {worker.memory_usage.toFixed(1)}%
                </Typography>

                <Box display="flex" gap={1}>
                  <Button
                    variant="contained"
                    size="small"
                    disabled={actionLoading === worker.id || worker.status === 'active'}
                    onClick={() => handleAction(worker.id, 'start')}
                  >
                    Iniciar
                  </Button>
                  <Button
                    variant="contained"
                    color="warning"
                    size="small"
                    disabled={actionLoading === worker.id || worker.status !== 'active'}
                    onClick={() => handleAction(worker.id, 'stop')}
                  >
                    Parar
                  </Button>
                  <Button
                    variant="contained"
                    color="error"
                    size="small"
                    disabled={actionLoading === worker.id}
                    onClick={() => handleAction(worker.id, 'restart')}
                  >
                    Reiniciar
                  </Button>
                </Box>
              </Paper>
            </Grid>
          ))}
        </Grid>
      )}

      <Snackbar
        open={!!error}
        autoHideDuration={6000}
        onClose={() => setError(null)}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        <Alert severity="error" onClose={() => setError(null)}>
          {error}
        </Alert>
      </Snackbar>

      <Snackbar
        open={!!successMsg}
        autoHideDuration={6000}
        onClose={() => setSuccessMsg(null)}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        <Alert severity="success" onClose={() => setSuccessMsg(null)}>
          {successMsg}
        </Alert>
      </Snackbar>

      <Dialog open={confirmDialog.open} onClose={cancelAction}>
        <DialogTitle>Confirmação</DialogTitle>
        <DialogContent>
          <DialogContentText>
            Tem certeza que deseja {confirmDialog.action} o worker {confirmDialog.workerId}?
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button onClick={cancelAction}>Cancelar</Button>
          <Button onClick={confirmAction} autoFocus>
            Confirmar
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}

export default Workers;
