import React from 'react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, AreaChart, Area } from 'recharts';

const Charts = ({ data, type = 'line', metrics = ['cpu_percent', 'memory_percent', 'disk_percent'] }) => {
  const colors = {
    cpu_percent: '#8884d8',
    memory_percent: '#82ca9d',
    disk_percent: '#ffc658',
    network_rx: '#ff7300',
    network_tx: '#00ff00'
  };

  const labels = {
    cpu_percent: 'CPU %',
    memory_percent: 'Memória %',
    disk_percent: 'Disco %',
    network_rx: 'Rede RX KB/s',
    network_tx: 'Rede TX KB/s'
  };

  if (type === 'area') {
    return (
      <ResponsiveContainer width="100%" height={300}>
        <AreaChart
          data={data}
          margin={{
            top: 10, right: 30, left: 0, bottom: 0,
          }}
        >
          <CartesianGrid strokeDasharray="3 3" />
          <XAxis dataKey="timestamp" />
          <YAxis />
          <Tooltip />
          <Legend />
          {metrics.map(metric => (
            <Area
              key={metric}
              type="monotone"
              dataKey={metric}
              stackId="1"
              stroke={colors[metric]}
              fill={colors[metric]}
              name={labels[metric]}
            />
          ))}
        </AreaChart>
      </ResponsiveContainer>
    );
  }

  return (
    <ResponsiveContainer width="100%" height={300}>
      <LineChart
        data={data}
        margin={{
          top: 5, right: 30, left: 20, bottom: 5,
        }}
      >
        <CartesianGrid strokeDasharray="3 3" />
        <XAxis dataKey="timestamp" />
        <YAxis />
        <Tooltip />
        <Legend />
        {metrics.map(metric => (
          <Line
            key={metric}
            type="monotone"
            dataKey={metric}
            stroke={colors[metric]}
            activeDot={{ r: 8 }}
            name={labels[metric]}
          />
        ))}
      </LineChart>
    </ResponsiveContainer>
  );
};

export default Charts;
