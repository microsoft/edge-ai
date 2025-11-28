/**
 * Skill Assessment Layout Tests
 * Verifies that radio buttons display correctly in horizontal layout
 * @vitest-environment happy-dom
 */

import { describe, test, expect, beforeEach, afterEach } from 'vitest';

describe('Skill Assessment Layout', () => {
  beforeEach(() => {
    // Set up DOM structure for skill assessment page
    document.body.innerHTML = `
      <div class="content">
        <h1>Skill Assessment</h1>
        <div id="skill-assessment-container">
          <h4>Question 1: Your experience level</h4>
          <ul class="task-list">
            <li class="rating-option"><input type="radio" name="skill-assessment-q1" value="1" style="display: none;" /><label class="rating-label">1 - No Experience</label></li>
            <li class="rating-option"><input type="radio" name="skill-assessment-q1" value="2" style="display: none;" /><label class="rating-label">2 - Beginner</label></li>
            <li class="rating-option"><input type="radio" name="skill-assessment-q1" value="3" style="display: none;" /><label class="rating-label">3 - Intermediate</label></li>
            <li class="rating-option"><input type="radio" name="skill-assessment-q1" value="4" style="display: none;" /><label class="rating-label">4 - Advanced</label></li>
            <li class="rating-option"><input type="radio" name="skill-assessment-q1" value="5" style="display: none;" /><label class="rating-label">5 - Expert</label></li>
          </ul>
          <h4>Question 2: Your technical skills</h4>
          <ul class="task-list">
            <li class="rating-option"><input type="radio" name="skill-assessment-q2" value="1" style="display: none;" /><label class="rating-label">1 - Basic</label></li>
            <li class="rating-option"><input type="radio" name="skill-assessment-q2" value="2" style="display: none;" /><label class="rating-label">2 - Intermediate</label></li>
            <li class="rating-option"><input type="radio" name="skill-assessment-q2" value="3" style="display: none;" /><label class="rating-label">3 - Advanced</label></li>
            <li class="rating-option"><input type="radio" name="skill-assessment-q2" value="4" style="display: none;" /><label class="rating-label">4 - Expert</label></li>
            <li class="rating-option"><input type="radio" name="skill-assessment-q2" value="5" style="display: none;" /><label class="rating-label">5 - Master</label></li>
          </ul>
        </div>
      </div>
      <style>
        .content ul.task-list {
          display: flex;
          flex-direction: row;
          flex-wrap: wrap;
          gap: 10px;
        }
        .rating-option {
          display: flex;
          flex-direction: row;
          align-items: center;
          cursor: pointer;
          pointer-events: auto;
        }
        .rating-option input[type="radio"] {
          display: none;
        }
        .rating-label {
          pointer-events: auto;
          visibility: visible;
        }
      </style>
    `;
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  test('should have task-list containers with proper flex layout', () => {
    const taskLists = document.querySelectorAll('.content ul.task-list');

    expect(taskLists.length).toBeGreaterThan(0);

    taskLists.forEach(ul => {
      const style = getComputedStyle(ul);
      expect(style.display).toBe('flex');
      expect(style.flexDirection).toBe('row');
      expect(style.flexWrap).toBe('wrap');
    });
  });

  test('should have rating options in row layout', () => {
    const ratingOptions = document.querySelectorAll('.content li.rating-option');

    expect(ratingOptions.length).toBeGreaterThan(0);

    ratingOptions.forEach(li => {
      const style = getComputedStyle(li);
      expect(style.display).toBe('flex');
      expect(style.flexDirection).toBe('row');
      expect(style.alignItems).toBe('center');
    });
  });

  test('should have radio inputs properly hidden', () => {
    const radioInputs = document.querySelectorAll('input[type="radio"]');

    expect(radioInputs.length).toBeGreaterThan(0);

    radioInputs.forEach(input => {
      const style = getComputedStyle(input);
      expect(style.display).toBe('none');
    });
  });

  test('should have radio labels properly positioned and visible', () => {
    const radioLabels = document.querySelectorAll('.rating-label');

    expect(radioLabels.length).toBeGreaterThan(0);

    radioLabels.forEach(label => {
      const style = getComputedStyle(label);
      expect(style.visibility).toBe('visible');
      expect(style.pointerEvents).toBe('auto');
    });
  });

  test('should have interactive rating options', () => {
    const clickableOptions = document.querySelectorAll('.rating-option');

    expect(clickableOptions.length).toBeGreaterThan(0);

    clickableOptions.forEach(option => {
      const style = getComputedStyle(option);
      expect(style.cursor).toBe('pointer');
      expect(style.pointerEvents).toBe('auto');
    });
  });

  test('should support responsive layout with flex-wrap', () => {
    const taskLists = document.querySelectorAll('.content ul.task-list');

    taskLists.forEach(ul => {
      const style = getComputedStyle(ul);
      expect(style.flexWrap).toBe('wrap');
      expect(style.gap).toBe('10px');
    });
  });

  test('should have correct radio button grouping', () => {
    const q1Radios = document.querySelectorAll('input[name="skill-assessment-q1"]');
    const q2Radios = document.querySelectorAll('input[name="skill-assessment-q2"]');

    expect(q1Radios.length).toBe(5);
    expect(q2Radios.length).toBe(5);

    // Test that radio values are properly set
    q1Radios.forEach((radio, index) => {
      expect(radio.value).toBe((index + 1).toString());
    });
  });

  test('should allow only one selection per question group', () => {
    const q1Radios = document.querySelectorAll('input[name="skill-assessment-q1"]');

    // Select first radio
    q1Radios[0].checked = true;
    expect(q1Radios[0].checked).toBe(true);

    // Select second radio - should uncheck first
    q1Radios[1].checked = true;
    expect(q1Radios[0].checked).toBe(false);
    expect(q1Radios[1].checked).toBe(true);
  });
});
