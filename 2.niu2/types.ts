export interface SimulationState {
  isPlaying: boolean;
  time: number;
  position: number;
  velocity: number;
  acceleration: number;
  force: number;
  mass: number;
}

export interface DataPoint {
  time: string;
  position: number;
  velocity: number;
  acceleration: number;
}

export interface ChatMessage {
  role: 'user' | 'model';
  text: string;
  timestamp: number;
}

export enum PhysicsPreset {
  DEFAULT = 'DEFAULT',
  HEAVY_OBJECT = 'HEAVY_OBJECT',
  HIGH_FORCE = 'HIGH_FORCE',
  BALANCED = 'BALANCED'
}