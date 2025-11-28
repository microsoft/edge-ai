class PathProgressCalculator {
  calculatePathProgress(pathKataIds, allKataProgress) {
    if (!Array.isArray(pathKataIds) || pathKataIds.length === 0) {
      return {
        percentage: 0,
        completed: 0,
        total: 0,
        completedKataIds: []
      };
    }

    if (!allKataProgress || typeof allKataProgress !== 'object') {
      return {
        percentage: 0,
        completed: 0,
        total: pathKataIds.length,
        completedKataIds: []
      };
    }

    const completedKataIds = [];

    for (const kataId of pathKataIds) {
      const progress = allKataProgress[kataId];
      if (progress && progress.completionPercentage === 100) {
        completedKataIds.push(kataId);
      }
    }

    const completedCount = completedKataIds.length;
    const totalCount = pathKataIds.length;
    const percentage = totalCount > 0
      ? Math.round((completedCount / totalCount) * 100)
      : 0;

    return {
      percentage,
      completed: completedCount,
      total: totalCount,
      completedKataIds
    };
  }
}

export default new PathProgressCalculator();
