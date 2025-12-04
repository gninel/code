import { useState, useEffect, useRef, useCallback } from 'react';
import { SimulationState } from '../types';

const TIME_STEP = 0.016; // ~60 FPS

export const usePhysicsEngine = (initialForce: number, initialMass: number) => {
  const [isPlaying, setIsPlaying] = useState(false);
  const [force, setForce] = useState(initialForce);
  const [mass, setMass] = useState(initialMass);
  
  // Use refs for mutable physics state to avoid re-render loops during the animation frame
  const stateRef = useRef({
    time: 0,
    position: 0,
    velocity: 0,
    acceleration: initialForce / initialMass,
  });

  // State for UI rendering
  const [uiState, setUiState] = useState<Omit<SimulationState, 'isPlaying' | 'force' | 'mass'>>({
    time: 0,
    position: 0,
    velocity: 0,
    acceleration: initialForce / initialMass,
  });

  const requestRef = useRef<number>();

  const reset = useCallback(() => {
    setIsPlaying(false);
    stateRef.current = {
      time: 0,
      position: 0,
      velocity: 0,
      acceleration: force / mass,
    };
    setUiState(stateRef.current);
  }, [force, mass]);

  const animate = useCallback(() => {
    if (!isPlaying) return;

    // Update Physics
    const currentAcc = force / mass;
    stateRef.current.acceleration = currentAcc;
    
    // v = u + at
    stateRef.current.velocity += currentAcc * TIME_STEP;
    
    // s = ut + 0.5at^2 (incremental: ds = v*dt)
    stateRef.current.position += stateRef.current.velocity * TIME_STEP;
    
    stateRef.current.time += TIME_STEP;

    // Update UI State
    setUiState({ ...stateRef.current });

    requestRef.current = requestAnimationFrame(animate);
  }, [isPlaying, force, mass]);

  useEffect(() => {
    if (isPlaying) {
      requestRef.current = requestAnimationFrame(animate);
    } else {
      if (requestRef.current) cancelAnimationFrame(requestRef.current);
    }
    return () => {
      if (requestRef.current) cancelAnimationFrame(requestRef.current);
    };
  }, [isPlaying, animate]);

  // Update acceleration immediately when force/mass changes even if paused
  useEffect(() => {
    const newAcc = force / mass;
    stateRef.current.acceleration = newAcc;
    setUiState(prev => ({ ...prev, acceleration: newAcc }));
  }, [force, mass]);

  return {
    isPlaying,
    setIsPlaying,
    force,
    setForce,
    mass,
    setMass,
    reset,
    ...uiState
  };
};