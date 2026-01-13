// Certificate PDF Generation Utilities
// Handles client-side PDF generation for certificate templates

import jsPDF from 'jspdf';
import html2canvas from 'html2canvas';
import type { Canvas as FabricCanvas } from 'fabric';
import { replacePlaceholders, PlaceholderData, getSamplePlaceholderData } from './certificate-placeholders';

export interface CertificateExportOptions {
  format: 'A4' | 'Letter' | 'Custom';
  orientation: 'landscape' | 'portrait';
  quality: 'standard' | 'high' | 'print';
  filename?: string;
}

const QUALITY_SETTINGS = {
  standard: { scale: 1, imageQuality: 0.8 },
  high: { scale: 2, imageQuality: 0.92 },
  print: { scale: 3, imageQuality: 1 },
};

const FORMAT_SIZES = {
  A4: { width: 297, height: 210 }, // mm, landscape
  Letter: { width: 279.4, height: 215.9 }, // mm, landscape
  Custom: { width: 297, height: 210 }, // default to A4
};

/**
 * Export Fabric.js canvas to PDF
 */
export async function exportCanvasToPDF(
  canvas: FabricCanvas,
  options: CertificateExportOptions = {
    format: 'A4',
    orientation: 'landscape',
    quality: 'high',
  }
): Promise<Blob> {
  const quality = QUALITY_SETTINGS[options.quality];
  const format = FORMAT_SIZES[options.format];

  // Get canvas dimensions
  const width = options.orientation === 'landscape' ? format.width : format.height;
  const height = options.orientation === 'landscape' ? format.height : format.width;

  // Create high-resolution data URL from canvas
  const dataUrl = canvas.toDataURL({
    format: 'png',
    quality: quality.imageQuality,
    multiplier: quality.scale,
  });

  // Create PDF
  const pdf = new jsPDF({
    orientation: options.orientation,
    unit: 'mm',
    format: [width, height],
  });

  // Add image to PDF
  pdf.addImage(dataUrl, 'PNG', 0, 0, width, height);

  // Return as blob
  return pdf.output('blob');
}

/**
 * Download PDF directly
 */
export async function downloadCertificatePDF(
  canvas: FabricCanvas,
  options: CertificateExportOptions & { filename: string }
): Promise<void> {
  const blob = await exportCanvasToPDF(canvas, options);
  const url = URL.createObjectURL(blob);
  
  const link = document.createElement('a');
  link.href = url;
  link.download = options.filename.endsWith('.pdf') ? options.filename : `${options.filename}.pdf`;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}

/**
 * Export canvas to PNG image
 */
export function exportCanvasToPNG(
  canvas: FabricCanvas,
  quality: 'standard' | 'high' | 'print' = 'high'
): string {
  const settings = QUALITY_SETTINGS[quality];
  return canvas.toDataURL({
    format: 'png',
    quality: settings.imageQuality,
    multiplier: settings.scale,
  });
}

/**
 * Download PNG directly
 */
export function downloadCertificatePNG(
  canvas: FabricCanvas,
  filename: string,
  quality: 'standard' | 'high' | 'print' = 'high'
): void {
  const dataUrl = exportCanvasToPNG(canvas, quality);
  
  const link = document.createElement('a');
  link.href = dataUrl;
  link.download = filename.endsWith('.png') ? filename : `${filename}.png`;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
}

/**
 * Export HTML element to PDF (fallback method)
 */
export async function exportElementToPDF(
  element: HTMLElement,
  options: CertificateExportOptions = {
    format: 'A4',
    orientation: 'landscape',
    quality: 'high',
  }
): Promise<Blob> {
  const quality = QUALITY_SETTINGS[options.quality];
  const format = FORMAT_SIZES[options.format];

  // Capture element as canvas
  const canvas = await html2canvas(element, {
    scale: quality.scale,
    useCORS: true,
    allowTaint: true,
    backgroundColor: '#ffffff',
  });

  // Get dimensions
  const width = options.orientation === 'landscape' ? format.width : format.height;
  const height = options.orientation === 'landscape' ? format.height : format.width;

  // Create PDF
  const pdf = new jsPDF({
    orientation: options.orientation,
    unit: 'mm',
    format: [width, height],
  });

  const imgData = canvas.toDataURL('image/png', quality.imageQuality);
  pdf.addImage(imgData, 'PNG', 0, 0, width, height);

  return pdf.output('blob');
}

/**
 * Prepare canvas for export by replacing placeholders with actual data
 */
export function prepareCanvasForExport(
  canvas: FabricCanvas,
  data: PlaceholderData
): void {
  const objects = canvas.getObjects();
  
  objects.forEach((obj) => {
    if (obj.type === 'textbox' || obj.type === 'text' || obj.type === 'i-text') {
      const textObj = obj as { text?: string; set: (props: Record<string, unknown>) => void };
      if (textObj.text) {
        const newText = replacePlaceholders(textObj.text, data);
        textObj.set({ text: newText });
      }
    }
  });
  
  canvas.renderAll();
}

/**
 * Preview certificate with sample data
 */
export function previewWithSampleData(canvas: FabricCanvas): void {
  const sampleData = getSamplePlaceholderData();
  prepareCanvasForExport(canvas, sampleData);
}

/**
 * Store original placeholder text for restoration
 */
export function storeOriginalText(canvas: FabricCanvas): Map<string, string> {
  const originalText = new Map<string, string>();
  const objects = canvas.getObjects();
  
  objects.forEach((obj, index) => {
    if (obj.type === 'textbox' || obj.type === 'text' || obj.type === 'i-text') {
      const textObj = obj as { text?: string };
      if (textObj.text) {
        originalText.set(`obj_${index}`, textObj.text);
      }
    }
  });
  
  return originalText;
}

/**
 * Restore original placeholder text
 */
export function restoreOriginalText(
  canvas: FabricCanvas,
  originalText: Map<string, string>
): void {
  const objects = canvas.getObjects();
  
  objects.forEach((obj, index) => {
    if (obj.type === 'textbox' || obj.type === 'text' || obj.type === 'i-text') {
      const key = `obj_${index}`;
      const original = originalText.get(key);
      if (original) {
        const textObj = obj as { set: (props: Record<string, unknown>) => void };
        textObj.set({ text: original });
      }
    }
  });
  
  canvas.renderAll();
}

/**
 * Generate certificate with data and download
 */
export async function generateAndDownloadCertificate(
  canvas: FabricCanvas,
  data: PlaceholderData,
  filename: string,
  options?: Partial<CertificateExportOptions>
): Promise<void> {
  // Store original text
  const original = storeOriginalText(canvas);
  
  try {
    // Replace placeholders
    prepareCanvasForExport(canvas, data);
    
    // Download
    await downloadCertificatePDF(canvas, {
      format: 'A4',
      orientation: 'landscape',
      quality: 'high',
      filename,
      ...options,
    });
  } finally {
    // Restore original
    restoreOriginalText(canvas, original);
  }
}
