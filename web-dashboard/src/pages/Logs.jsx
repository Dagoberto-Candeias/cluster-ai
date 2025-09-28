import React, { useEffect, useState } from 'react';
import {
  Typography,
  Box,
  Paper,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Button,
  Chip,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TablePagination,
  CircularProgress,
  Alert,
  useTheme
} from '@mui/material';
import { Refresh as RefreshIcon, Search as SearchIcon } from '@mui/icons-material';
import axios from 'axios';

function Logs() {
  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(false);
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(25);
  const [totalLogs, setTotalLogs] = useState(0);
  const [filters, setFilters] = useState({
    level: '',
    component: '',
    search: ''
  });
  const theme = useTheme();

  const fetchLogs = async () => {
    setLoading(true);
    try {
      const params = {
        limit: rowsPerPage,
        offset: page * rowsPerPage,
        ...filters
      };

      // Remove empty filters
      Object.keys(params).forEach(key => {
        if (!params[key]) delete params[key];
      });

      const response = await axios.get('/api/logs', { params });
      setLogs(response.data);
      setTotalLogs(response.data.length); // This should come from backend pagination
    } catch (error) {
      console.error('Failed to fetch logs:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchLogs();
  }, [page, rowsPerPage, filters]);

  const handleFilterChange = (field, value) => {
    setFilters(prev => ({
      ...prev,
      [field]: value
    }));
    setPage(0); // Reset to first page when filters change
  };

  const handlePageChange = (event, newPage) => {
    setPage(newPage);
  };

  const handleRowsPerPageChange = (event) => {
    setRowsPerPage(parseInt(event.target.value, 10));
    setPage(0);
  };

  const getLevelColor = (level) => {
    switch (level?.toLowerCase()) {
      case 'error':
      case 'critical':
        return 'error';
      case 'warning':
        return 'warning';
      case 'info':
        return 'info';
      case 'debug':
        return 'default';
      default:
        return 'default';
    }
  };

  const formatTimestamp = (timestamp) => {
    try {
      const date = new Date(timestamp);
      return date.toLocaleString();
    } catch {
      return timestamp;
    }
  };

  const filteredLogs = logs.filter(log => {
    const matchesSearch = !filters.search ||
      log.message.toLowerCase().includes(filters.search.toLowerCase()) ||
      log.component.toLowerCase().includes(filters.search.toLowerCase());

    return matchesSearch;
  });

  return (
    <Box p={3}>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4" component="h1">
          System Logs
        </Typography>
        <Button
          variant="outlined"
          startIcon={<RefreshIcon />}
          onClick={fetchLogs}
          disabled={loading}
        >
          Refresh
        </Button>
      </Box>

      {/* Filters */}
      <Paper sx={{ p: 2, mb: 3 }}>
        <Typography variant="h6" gutterBottom>
          Filters
        </Typography>
        <Box display="flex" gap={2} flexWrap="wrap" alignItems="center">
          <TextField
            label="Search"
            variant="outlined"
            size="small"
            value={filters.search}
            onChange={(e) => handleFilterChange('search', e.target.value)}
            InputProps={{
              startAdornment: <SearchIcon sx={{ mr: 1, color: 'text.secondary' }} />
            }}
            sx={{ minWidth: 200 }}
          />

          <FormControl size="small" sx={{ minWidth: 120 }}>
            <InputLabel>Level</InputLabel>
            <Select
              value={filters.level}
              label="Level"
              onChange={(e) => handleFilterChange('level', e.target.value)}
            >
              <MenuItem value="">All</MenuItem>
              <MenuItem value="ERROR">Error</MenuItem>
              <MenuItem value="WARNING">Warning</MenuItem>
              <MenuItem value="INFO">Info</MenuItem>
              <MenuItem value="DEBUG">Debug</MenuItem>
            </Select>
          </FormControl>

          <FormControl size="small" sx={{ minWidth: 150 }}>
            <InputLabel>Component</InputLabel>
            <Select
              value={filters.component}
              label="Component"
              onChange={(e) => handleFilterChange('component', e.target.value)}
            >
              <MenuItem value="">All</MenuItem>
              <MenuItem value="DASK">Dask</MenuItem>
              <MenuItem value="OLLAMA">Ollama</MenuItem>
              <MenuItem value="WEBUI">WebUI</MenuItem>
              <MenuItem value="MONITORING">Monitoring</MenuItem>
              <MenuItem value="SYSTEM">System</MenuItem>
            </Select>
          </FormControl>

          <Button
            variant="text"
            onClick={() => setFilters({ level: '', component: '', search: '' })}
          >
            Clear Filters
          </Button>
        </Box>
      </Paper>

      {/* Logs Table */}
      <Paper>
        {loading ? (
          <Box display="flex" justifyContent="center" p={4}>
            <CircularProgress />
          </Box>
        ) : filteredLogs.length === 0 ? (
          <Box p={4} textAlign="center">
            <Typography variant="h6" color="text.secondary">
              No logs found
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Try adjusting your filters or check if the system is generating logs.
            </Typography>
          </Box>
        ) : (
          <>
            <TableContainer>
              <Table>
                <TableHead>
                  <TableRow>
                    <TableCell>Timestamp</TableCell>
                    <TableCell>Level</TableCell>
                    <TableCell>Component</TableCell>
                    <TableCell>Message</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {filteredLogs.map((log, index) => (
                    <TableRow key={`${log.timestamp}-${index}`} hover>
                      <TableCell sx={{ fontFamily: 'monospace', fontSize: '0.875rem' }}>
                        {formatTimestamp(log.timestamp)}
                      </TableCell>
                      <TableCell>
                        <Chip
                          label={log.level}
                          color={getLevelColor(log.level)}
                          size="small"
                          variant="outlined"
                        />
                      </TableCell>
                      <TableCell sx={{ fontWeight: 'medium' }}>
                        {log.component}
                      </TableCell>
                      <TableCell sx={{ maxWidth: 400 }}>
                        <Typography
                          variant="body2"
                          sx={{
                            wordBreak: 'break-word',
                            whiteSpace: 'pre-wrap'
                          }}
                        >
                          {log.message}
                        </Typography>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
            <TablePagination
              component="div"
              count={totalLogs}
              page={page}
              onPageChange={handlePageChange}
              rowsPerPage={rowsPerPage}
              onRowsPerPageChange={handleRowsPerPageChange}
              rowsPerPageOptions={[10, 25, 50, 100]}
            />
          </>
        )}
      </Paper>

      {/* Summary */}
      <Box mt={3}>
        <Alert severity="info">
          Showing {filteredLogs.length} of {totalLogs} logs
          {filters.level && ` filtered by level: ${filters.level}`}
          {filters.component && `, component: ${filters.component}`}
          {filters.search && `, search: "${filters.search}"`}
        </Alert>
      </Box>
    </Box>
  );
}

export default Logs;
