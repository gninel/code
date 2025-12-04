import React from 'react';
import { Play, Pause, RotateCcw, Weight, Wind } from 'lucide-react';

interface ControlPanelProps {
  isPlaying: boolean;
  force: number;
  mass: number;
  setForce: (val: number) => void;
  setMass: (val: number) => void;
  togglePlay: () => void;
  reset: () => void;
}

export const ControlPanel: React.FC<ControlPanelProps> = ({
  isPlaying,
  force,
  mass,
  setForce,
  setMass,
  togglePlay,
  reset
}) => {
  return (
    <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-200 space-y-6">
      
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-lg font-semibold text-slate-800">实验控制</h2>
        <div className="flex gap-2">
          <button
            onClick={togglePlay}
            title={isPlaying ? "暂停" : "开始"}
            className={`flex items-center justify-center w-12 h-12 rounded-full transition-all ${
              isPlaying 
              ? 'bg-amber-100 text-amber-600 hover:bg-amber-200' 
              : 'bg-indigo-600 text-white hover:bg-indigo-700 shadow-lg shadow-indigo-200'
            }`}
          >
            {isPlaying ? <Pause size={24} /> : <Play size={24} fill="currentColor" />}
          </button>
          <button
            onClick={reset}
            title="重置"
            className="flex items-center justify-center w-12 h-12 rounded-full bg-slate-100 text-slate-600 hover:bg-slate-200 transition-all"
          >
            <RotateCcw size={20} />
          </button>
        </div>
      </div>

      {/* Force Control */}
      <div className="space-y-3">
        <div className="flex justify-between items-center">
          <label className="flex items-center gap-2 text-sm font-medium text-slate-700">
            <Wind size={16} className="text-blue-500" />
            外力 (F)
          </label>
          <span className="text-sm font-bold bg-blue-50 text-blue-700 px-2 py-1 rounded">
            {force} N
          </span>
        </div>
        <input
          type="range"
          min="0"
          max="100"
          step="1"
          value={force}
          onChange={(e) => setForce(Number(e.target.value))}
          className="w-full h-2 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-blue-600 hover:accent-blue-500 transition-all"
        />
      </div>

      {/* Mass Control */}
      <div className="space-y-3">
        <div className="flex justify-between items-center">
          <label className="flex items-center gap-2 text-sm font-medium text-slate-700">
            <Weight size={16} className="text-emerald-500" />
            质量 (m)
          </label>
          <span className="text-sm font-bold bg-emerald-50 text-emerald-700 px-2 py-1 rounded">
            {mass} kg
          </span>
        </div>
        <input
          type="range"
          min="1"
          max="50"
          step="0.5"
          value={mass}
          onChange={(e) => setMass(Number(e.target.value))}
          className="w-full h-2 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-emerald-600 hover:accent-emerald-500 transition-all"
        />
      </div>

      <div className="pt-4 border-t border-slate-100">
        <div className="flex justify-between items-center text-xs text-slate-500">
          <span>计算加速度 (a = F/m):</span>
          <span className="text-lg font-mono font-bold text-indigo-600">
            {(force / mass).toFixed(2)} m/s²
          </span>
        </div>
      </div>

    </div>
  );
};