import React from 'react';
import 'grapesjs/dist/css/grapes.min.css';
import { useParams } from 'react-router-dom';
import { usePageBuilder } from './page-builder/usePageBuilder';
import { BuilderToolbar } from './page-builder/BuilderToolbar';
import { LeftPanel } from './page-builder/LeftPanel';
import { RightPanel } from './page-builder/RightPanel';
import { CanvasArea } from './page-builder/CanvasArea';

/**
 * EventPageBuilder
 *
 * Framer-inspired GrapesJS-based landing page builder for events.
 * - Dark theme with professional design tools layout
 * - Top toolbar with tools and actions
 * - Left panel: Pages/Layers/Assets tabs
 * - Center: Canvas with device/breakpoint controls
 * - Right panel: Design/Prototype tabs with style management
 */
export const EventPageBuilder: React.FC = () => {
  const { eventId } = useParams<{ eventId: string }>();

  const {
    containerRef,
    slug,
    loading,
    saving,
    device,
    handleDeviceChange,
    handlePreview,
    handleSave,
  } = usePageBuilder({ eventId });

  if (loading) {
    return (
      <div className="flex h-screen items-center justify-center bg-[hsl(220,13%,6%)]">
        <div className="flex flex-col items-center gap-3">
          <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent" />
          <p className="text-sm text-muted-foreground">Loading builder...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="flex h-screen flex-col overflow-hidden bg-[hsl(220,13%,6%)]">
      {/* Top Toolbar */}
      <BuilderToolbar
        projectName={slug || 'Event Page'}
        onSave={handleSave}
        onPreview={handlePreview}
        saving={saving}
      />

      {/* Main Content */}
      <div className="flex flex-1 min-h-0">
        {/* Left Panel */}
        <LeftPanel />

        {/* Canvas Area */}
        <CanvasArea
          containerRef={containerRef}
          device={device}
          onDeviceChange={handleDeviceChange}
        />

        {/* Right Panel */}
        <RightPanel />
      </div>

      {/* GrapesJS Custom Styles for dark theme */}
      <style>{`
        /* Force dark theme on GrapesJS */
        .gjs-editor-container {
          position: relative;
          background: hsl(220, 13%, 6%);
        }
        .gjs-editor {
          height: 100% !important;
          background: hsl(220, 13%, 6%) !important;
        }
        .gjs-cv-canvas {
          width: 100% !important;
          height: 100% !important;
          top: 0 !important;
          left: 0 !important;
          background: hsl(220, 13%, 6%) !important;
        }
        .gjs-frame-wrapper {
          background-color: hsl(220, 13%, 12%);
          border-radius: 8px;
          overflow: hidden;
        }
        
        /* Hide default GrapesJS panels */
        .gjs-pn-panels {
          display: none !important;
        }
        
        /* Block styling */
        .gjs-block {
          width: 100%;
          min-height: auto;
          padding: 10px;
          margin-bottom: 8px;
          border-radius: 6px;
          border: 1px solid hsl(220, 13%, 18%);
          background: hsl(220, 13%, 12%);
          color: hsl(210, 40%, 98%);
          transition: all 0.15s ease;
        }
        .gjs-block:hover {
          border-color: hsl(221, 83%, 53%);
          background: hsl(220, 13%, 15%);
        }
        .gjs-block svg {
          fill: hsl(215, 20%, 65%);
        }
        .gjs-block-label {
          font-size: 11px;
          color: hsl(210, 40%, 98%);
        }
        
        /* Block categories */
        .gjs-block-category {
          border-bottom: 1px solid hsl(220, 13%, 18%);
          background: transparent !important;
        }
        .gjs-block-category .gjs-title {
          padding: 10px 8px;
          font-size: 11px;
          font-weight: 500;
          color: hsl(215, 20%, 65%);
          background: transparent !important;
          border: none;
        }
        .gjs-block-category .gjs-caret-icon {
          color: hsl(215, 20%, 65%);
        }
        
        /* Style manager */
        .gjs-sm-sector {
          border-bottom: 1px solid hsl(220, 13%, 18%);
          background: transparent !important;
        }
        .gjs-sm-sector-title {
          padding: 10px;
          font-size: 11px;
          font-weight: 500;
          color: hsl(210, 40%, 98%);
          background: transparent !important;
          border: none;
        }
        .gjs-sm-properties {
          padding: 8px;
          background: transparent !important;
        }
        .gjs-sm-property {
          margin-bottom: 8px;
        }
        .gjs-sm-label {
          font-size: 10px;
          color: hsl(215, 20%, 65%);
        }
        .gjs-field {
          background: hsl(220, 13%, 12%);
          border: 1px solid hsl(220, 13%, 22%);
          border-radius: 4px;
          color: hsl(210, 40%, 98%);
        }
        .gjs-field:focus-within {
          border-color: hsl(221, 83%, 53%);
        }
        .gjs-field input,
        .gjs-field select {
          color: hsl(210, 40%, 98%);
          background: transparent;
        }
        .gjs-field input::placeholder {
          color: hsl(215, 20%, 45%);
        }
        
        /* Color picker */
        .gjs-sm-colorp-c {
          background: hsl(220, 13%, 12%);
          border: 1px solid hsl(220, 13%, 22%);
          border-radius: 4px;
        }
        
        /* Layer manager */
        .gjs-layer {
          background: transparent;
          font-size: 11px;
          color: hsl(210, 40%, 98%);
        }
        .gjs-layer-name {
          color: hsl(210, 40%, 98%);
        }
        .gjs-layer:hover {
          background: hsl(220, 13%, 15%);
        }
        .gjs-layer.gjs-selected {
          background: hsl(221, 83%, 53% / 0.2);
        }
        .gjs-layer-title {
          background: transparent !important;
        }
        
        /* Trait manager */
        .gjs-trt-trait {
          padding: 8px 0;
          border-bottom: 1px solid hsl(220, 13%, 18%);
        }
        .gjs-trt-trait .gjs-label {
          color: hsl(215, 20%, 65%);
          font-size: 10px;
        }
        
        /* Selection highlight */
        .gjs-selected {
          outline: 2px solid hsl(221, 83%, 53%) !important;
          outline-offset: -2px;
        }
        
        /* Resize handles */
        .gjs-resizer-h {
          border-color: hsl(221, 83%, 53%);
        }
        
        /* Toolbar floating */
        .gjs-toolbar {
          background: hsl(220, 13%, 15%);
          border: 1px solid hsl(220, 13%, 22%);
          border-radius: 6px;
        }
        .gjs-toolbar-item {
          color: hsl(210, 40%, 98%);
        }
        .gjs-toolbar-item:hover {
          color: hsl(221, 83%, 66%);
        }
        
        /* Badge */
        .gjs-badge {
          background: hsl(221, 83%, 53%);
          color: hsl(210, 40%, 98%);
        }
        
        /* Placeholder when dragging */
        .gjs-placeholder {
          border-color: hsl(221, 83%, 53%);
          background: hsl(221, 83%, 53% / 0.1);
        }
      `}</style>
    </div>
  );
};
