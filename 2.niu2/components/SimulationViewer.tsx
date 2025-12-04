import React, { useMemo } from 'react';
import { ArrowRight } from 'lucide-react';

interface SimulationViewerProps {
  position: number;
  velocity: number;
  force: number;
  mass: number;
}

export const SimulationViewer: React.FC<SimulationViewerProps> = ({
  position,
  velocity,
  force,
  mass
}) => {
  // Scale factor for visualization (how many pixels per meter)
  const PIXELS_PER_METER = 10;
  
  // Calculate visual position
  const visualPosition = Math.min(position * PIXELS_PER_METER, 10000); // Cap it so CSS doesn't break
  
  // Box size calculation based on mass (visual feedback)
  const boxSize = Math.min(Math.max(40, mass * 3), 120); // 40px to 120px

  // Force arrow length
  const arrowLength = Math.min(force * 2, 200);

  return (
    <div className="relative w-full h-64 bg-slate-100 rounded-2xl overflow-hidden border border-slate-300 shadow-inner">
      
      {/* Background Grid/Ruler */}
      <div 
        className="absolute inset-0 opacity-20"
        style={{
            backgroundImage: 'linear-gradient(to right, #94a3b8 1px, transparent 1px)',
            backgroundSize: '50px 100%',
            transform: `translateX(${-visualPosition % 50}px)` // Parallax/Movement effect
        }} 
      />

      {/* Ground */}
      <div className="absolute bottom-0 w-full h-12 bg-slate-300 border-t border-slate-400" />

      {/* Moving Object Container */}
      
      <div className="absolute inset-0 flex items-end pb-12 justify-center">
         <div className="relative flex flex-col items-center justify-end transition-all duration-75">
            
            {/* Force Vector Arrow */}
            {force > 0 && (
                <div 
                    className="absolute bottom-full mb-2 flex items-center text-blue-600 font-bold transition-all duration-300"
                    style={{ 
                        left: '50%', 
                        width: `${arrowLength}px`,
                        opacity: 0.8
                    }}
                >
                    <div className="h-1 bg-blue-500 w-full rounded-full" />
                    <ArrowRight size={24} className="-ml-2" />
                    <span className="absolute -top-6 left-1/2 -translate-x-1/2 whitespace-nowrap text-xs bg-white/80 px-1 rounded">
                        F = {force}N
                    </span>
                </div>
            )}

            {/* The Mass Block */}
            <div 
                className="bg-gradient-to-br from-indigo-500 to-indigo-700 rounded-lg shadow-lg flex items-center justify-center text-white font-bold border-2 border-indigo-800 z-10 transition-all duration-300"
                style={{
                    width: `${boxSize}px`,
                    height: `${boxSize}px`,
                }}
            >
                {mass}kg
            </div>

            {/* Velocity indicator (wheels/motion blur) */}
            {velocity > 0.1 && (
                 <div className="absolute -bottom-2 flex gap-2 w-full justify-around opacity-50">
                    <div className="animate-spin w-4 h-4 rounded-full border-2 border-slate-600 border-t-transparent" style={{ animationDuration: `${Math.max(0.1, 1/velocity)}s`}} />
                    <div className="animate-spin w-4 h-4 rounded-full border-2 border-slate-600 border-t-transparent" style={{ animationDuration: `${Math.max(0.1, 1/velocity)}s`}} />
                 </div>
            )}
         </div>
      </div>

      {/* HUD */}
      <div className="absolute top-4 right-4 bg-white/90 backdrop-blur p-2 rounded-lg border border-slate-200 text-xs font-mono text-slate-600 shadow-sm">
        <div>位移: {position.toFixed(2)} m</div>
        <div>速度: {velocity.toFixed(2)} m/s</div>
      </div>
      
      <div className="absolute top-4 left-4 text-slate-400 text-sm italic">
        视角跟随物体
      </div>

    </div>
  );
};