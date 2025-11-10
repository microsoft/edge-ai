/**
 * Calculate completion percentage from checkbox states
 * @param {Object} checkboxStates - Object with boolean completion values
 * @returns {{total: number, completed: number, percentage: number}} Completion statistics
 */
export function calculateCompletion(checkboxStates = {}) {
  const values = Object.values(checkboxStates);
  const total = values.length;
  const completed = values.filter(value => value === true).length;
  const percentage = total > 0 ? Math.round((completed / total) * 100) : 0;

  return { total, completed, percentage };
}
