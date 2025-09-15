import React, { useState, useEffect } from 'react';
import { Card, CardContent, Typography, Box, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Paper, Chip, Button } from '@mui/material';
import { PlayArrow, Stop, Refresh } from '@mui/icons-material';
import { useApi } from '../contexts/ApiContext';

// Mock data for demonstration
const mockWorkers = [
  { id: 'worker-1', name: 'Worker Node 1', status: 'active', cpu: 45, memory: 67, tasks: 12, address: '192.168.1.101:8786' },
  { id: 'worker-2', name: 'Worker Node 2', status: 'active', cpu: 32, memory: 45, tasks: 8, address: '192.168.1.102:8786' },
  { id: 'worker-3', name: 'Worker Node 3', status: 'idle', cpu: 5, memory: 12, tasks: 0, address: '192.168.1.103:8786' },
  { id: 'worker-4', name: 'Worker Node 4', status: 'offline', cpu: 0, memory: 0, tasks: 0, address: '192.168.1.104:8786' },
  { id: 'worker-5', name: 'Worker Node 5', status: 'active', cpu: 78, memory: 89, tasks: 15, address: '192.168.1.105:8786' },
];

const WorkersPage: React.FC = () => {
  const { api } = useApi();
  const [workers, setWorkers] = useState(mockWorkers);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    // TODO: Fetch real worker data from API
    // fetchWorkers();
  }, [api]);

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active': return 'success';
      case 'idle': return 'warning';
      case 'offline': return 'error';
      default: return 'default';
    }
  };

  const handleWorkerAction = async (workerId: string, action: string) => {
    setLoading(true);
    try {
      // TODO: Implement worker control API calls
      console.log(`${action} worker ${workerId}`);
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 1000));
    } catch (error) {
      console.error(`Failed to ${action} worker:`, error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4" gutterBottom>
          Workers Management
        </Typography>
        <Button
          variant="contained"
          startIcon={<Refresh />}
          onClick={() => window.location.reload()}
          disabled={loading}
        >
          Refresh
        </Button>
      </Box>

      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Cluster Workers
          </Typography>
          <TableContainer component={Paper}>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Name</TableCell>
                  <TableCell>Status</TableCell>
                  <TableCell>CPU Usage</TableCell>
                  <TableCell>Memory Usage</TableCell>
                  <TableCell>Active Tasks</TableCell>
                  <TableCell>Address</TableCell>
                  <TableCell>Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {workers.map((worker) => (
                  <TableRow key={worker.id}>
                    <TableCell>{worker.name}</TableCell>
                    <TableCell>
                      <Chip
                        label={worker.status}
                        color={getStatusColor(worker.status) as any}
                        size="small"
                      />
                    </TableCell>
                    <TableCell>{worker.cpu}%</TableCell>
                    <TableCell>{worker.memory}%</TableCell>
                    <TableCell>{worker.tasks}</TableCell>
                    <TableCell>{worker.address}</TableCell>
                    <TableCell>
                      <Box display="flex" gap={1}>
                        {worker.status === 'offline' ? (
                          <Button
                            size="small"
                            variant="contained"
                            color="success"
                            startIcon={<PlayArrow />}
                            onClick={() => handleWorkerAction(worker.id, 'start')}
                            disabled={loading}
                          >
                            Start
                          </Button>
                        ) : (
                          <Button
                            size="small"
                            variant="outlined"
                            color="error"
                            startIcon={<Stop />}
                            onClick={() => handleWorkerAction(worker.id, 'stop')}
                            disabled={loading}
                          >
                            Stop
                          </Button>
                        )}
                      </Box>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        </CardContent>
      </Card>
    </Box>
  );
};

export default WorkersPage;
