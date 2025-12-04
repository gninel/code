import React, { useState, useEffect } from 'react';
import { Beaker } from 'lucide-react';
import { usePhysicsEngine } from './hooks/usePhysicsEngine';
import { ControlPanel } from './components/ControlPanel';
import { SimulationViewer } from './components/SimulationViewer';
import { ChartsPanel } from './components/ChartsPanel';
import { AITutor } from './components/AITutor';
import { DataPoint } from './types';

export default function App() {
  // Initialize physics engine with defaults (Force=50N, Mass=10kg)
  const physics = usePhysicsEngine(50, 10);
  
  // State for chart history
  const [dataHistory, setDataHistory] = useState<DataPoint[]>([]);

  // Collect data points for charts
  useEffect(() => {
    if (physics.isPlaying) {
      const newPoint: DataPoint = {
        time: physics.time.toFixed(2),
        position: parseFloat(physics.position.toFixed(2)),
        velocity: parseFloat(physics.velocity.toFixed(2)),
        acceleration: parseFloat(physics.acceleration.toFixed(2))
      };

      setDataHistory(prev => {
        const updated = [...prev, newPoint];
        // Keep last 200 points to avoid memory issues/lag
        if (updated.length > 200) return updated.slice(updated.length - 200);
        return updated;
      });
    } else if (physics.time === 0) {
      // Reset charts when simulation resets
      setDataHistory([]);
    }
  }, [physics.time, physics.isPlaying, physics.position, physics.velocity, physics.acceleration]);

  return (
    <div className="min-h-screen bg-slate-50 p-4 md:p-8 font-sans text-slate-900">
      
      {/* Top Navigation / Header */}
      <header className="max-w-7xl mx-auto mb-8 flex items-center gap-3 pb-6 border-b border-slate-200">
        <div className="w-10 h-10 bg-indigo-600 rounded-xl flex items-center justify-center shadow-lg shadow-indigo-200 text-white">
          <Beaker size={24} />
        </div>
        <div>
          <h1 className="text-2xl font-bold text-slate-800">牛顿第二定律实验室</h1>
          <p className="text-slate-500 text-sm">交互式 <span className="font-mono text-indigo-600 bg-indigo-50 px-1 rounded">F = ma</span> 仿真演示</p>
        </div>
      </header>

      <main className="max-w-7xl mx-auto grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Left Column: Controls & Visualization (2/3 width) */}
        <div className="lg:col-span-2 space-y-6">
          
          {/* Visualizer */}
          <section className="space-y-2">
             <SimulationViewer 
                position={physics.position}
                velocity={physics.velocity}
                force={physics.force}
                mass={physics.mass}
             />
          </section>

          {/* Controls */}
          <section>
            <ControlPanel 
              isPlaying={physics.isPlaying}
              togglePlay={() => physics.setIsPlaying(!physics.isPlaying)}
              reset={physics.reset}
              force={physics.force}
              setForce={physics.setForce}
              mass={physics.mass}
              setMass={physics.setMass}
            />
          </section>

          {/* Charts */}
          <section>
             <h2 className="text-lg font-semibold text-slate-800 mb-4">实时数据曲线</h2>
             <ChartsPanel data={dataHistory} />
          </section>
        </div>

        {/* Right Column: AI Tutor (1/3 width) */}
        <div className="lg:col-span-1 h-[600px] lg:h-auto lg:sticky lg:top-8">
          <AITutor 
            simulationState={{
              isPlaying: physics.isPlaying,
              time: physics.time,
              position: physics.position,
              velocity: physics.velocity,
              acceleration: physics.acceleration,
              force: physics.force,
              mass: physics.mass
            }} 
          />
        </div>

      </main>
    </div>
  );
}