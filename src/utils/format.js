/**
 * Format a dollar amount for display.
 * @param {number} dollars - Amount in dollars (e.g. 12.99)
 * @returns {string} Formatted price string
 */
export function formatPrice(dollars) {
  return `$${dollars.toFixed(2)}`;
}

/**
 * Format a date for API response.
 */
export function formatDate(date) {
  if (!date) return null;
  return new Date(date).toISOString().split('T')[0];
}
