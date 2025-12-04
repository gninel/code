import React from 'react';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend
} from 'recharts';
import { DataPoint } from '../types';

interface ChartsPanelProps {
  data: DataPoint[];
}

export const ChartsPanel: React.FC<ChartsPanelProps> = ({ data }) => {
  // Optimize: Slice data if it gets too large to maintain performance
  const chartData = data.length > 100 ? data.slice(data.length - 100) : data;

  return (
    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
      {/* Acceleration Chart */}
      <div className="bg-white p-4 rounded-xl shadow-sm border border-slate-200 flex flex-col h-64">
        <h3 className="text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">加速度 (a)</h3>
        <div className="flex-1 min-h-0">
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={chartData}>
              <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e2e8f0" />
              <XAxis dataKey="time" hide />
              <YAxis domain={[0, 'auto']} stroke="#64748b" fontSize={10} />
              <Tooltip 
                contentStyle={{ backgroundColor: '#fff', borderRadius: '8px', border: '1px solid #e2e8f0' }}
                itemStyle={{ fontSize: '12px', fontWeight: 600 }}
                labelFormatter={() => ''}
              />
              <Line 
                type="monotone" 
                dataKey="acceleration" 
                stroke="#ef4444" 
                strokeWidth={2} 
                dot={false}
                isAnimationActive={false}
              />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Velocity Chart */}
      <div className="bg-white p-4 rounded-xl shadow-sm border border-slate-200 flex flex-col h-64">
        <h3 className="text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">速度 (v)</h3>
        <div className="flex-1 min-h-0">
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={chartData}>
              <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e2e8f0" />
              <XAxis dataKey="time" hide />
              <YAxis stroke="#64748b" fontSize={10} />
              <Tooltip 
                 contentStyle={{ backgroundColor: '#fff', borderRadius: '8px', border: '1px solid #e2e8f0' }}
                 itemStyle={{ fontSize: '12px', fontWeight: 600 }}
                 labelFormatter={() => ''}
              />
              <Line 
                type="monotone" 
                dataKey="velocity" 
                stroke="#3b82f6" 
                strokeWidth={2} 
                dot={false} 
                isAnimationActive={false}
              />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Position Chart */}
      <div className="bg-white p-4 rounded-xl shadow-sm border border-slate-200 flex flex-col h-64">
        <h3 className="text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">位移 (x)</h3>
        <div className="flex-1 min-h-0">
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={chartData}>
              <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e2e8f0" />
              <XAxis dataKey="time" hide />
              <YAxis stroke="#64748b" fontSize={10} />
              <Tooltip 
                 contentStyle={{ backgroundColor: '#fff', borderRadius: '8px', border: '1px solid #e2e8f0' }}
                 itemStyle={{ fontSize: '12px', fontWeight: 600 }}
                 labelFormatter={() => ''}
              />
              <Line 
                type="monotone" 
                dataKey="position" 
                stroke="#10b981" 
                strokeWidth={2} 
                dot={false} 
                isAnimationActive={false}
              />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
};