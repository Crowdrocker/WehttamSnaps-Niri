.pragma library

/**
 * Wrap text in a nicely styled HTML container for display
 * @param {string} text - The text to display
 * @returns {string} HTML string
 */
function wrapTextForDisplay(text) {
  // Escape HTML special characters
  const escapeHtml = (s) =>
    s.replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");

  return `
<div style="
  font-family: 'Fira Code', 'Courier New', monospace;
  white-space: pre-wrap;
  background: linear-gradient(135deg, #2c3e50, #34495e);
  color: #ecf0f1;
  padding: 16px;
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.3);
  overflow-x: auto;
  line-height: 1.5;
  font-size: 14px;
  border: 1px solid #3d566e;
">
${escapeHtml(text)}
</div>
`;
}
