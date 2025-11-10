/**
 * Calculate completion percentage from checkbox states
 * @param {Object} checkboxStates - Object mapping task IDs to completion status (true/false)
 * @returns {Object} Object containing total, completed, and percentage
 */
export function calculateCompletion(checkboxStates = {}) {
  const values = Object.values(checkboxStates);
  const total = values.length;
  const completed = values.filter(value => value === true).length;
  const percentage = total > 0 ? Math.round((completed / total) * 100) : 0;
  return { total, completed, percentage };
}
