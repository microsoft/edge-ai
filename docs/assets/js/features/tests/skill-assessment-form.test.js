/**
 * Skill Assessment Form Tests
 * Tests for radio button conversion and per-question grouping functionality
 *
 * @jest-environment jsdom
 */

import { SkillAssessmentForm } from '../skill-assessment-form.js';

describe('SkillAssessmentForm', () => {
  let assessmentForm;
  let mockDocument;

  beforeEach(() => {
    // Set up DOM environment
    document.body.innerHTML = `
      <div class="content">
        <h4>1. Question One</h4>
        <ul>
          <li><input type="checkbox"> 1 - Option one</li>
          <li><input type="checkbox"> 2 - Option two</li>
          <li><input type="checkbox"> 3 - Option three</li>
        </ul>

        <h4>2. Question Two</h4>
        <ul>
          <li><input type="checkbox"> 1 - Option one</li>
          <li><input type="checkbox"> 2 - Option two</li>
          <li><input type="checkbox"> 3 - Option three</li>
        </ul>
      </div>
    `;

    assessmentForm = new SkillAssessmentForm({ debug: true });
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  describe('groupCheckboxesByQuestions', () => {
    test('should group checkboxes by H4 headings', () => {
      const checkboxes = document.querySelectorAll('input[type="checkbox"]');
      const groups = assessmentForm.groupCheckboxesByQuestions(checkboxes);

      expect(groups).toHaveLength(2);
      expect(groups[0].heading).toBe('1. Question One');
      expect(groups[0].checkboxes).toHaveLength(3);
      expect(groups[1].heading).toBe('2. Question Two');
      expect(groups[1].checkboxes).toHaveLength(3);
    });

    test('should handle empty checkbox list', () => {
      const groups = assessmentForm.groupCheckboxesByQuestions([]);
      expect(groups).toHaveLength(0);
    });

    test('should handle missing headings gracefully', () => {
      document.body.innerHTML = `
        <div class="content">
          <ul>
            <li><input type="checkbox"> 1 - Option one</li>
            <li><input type="checkbox"> 2 - Option two</li>
          </ul>
        </div>
      `;

      const checkboxes = document.querySelectorAll('input[type="checkbox"]');
      const groups = assessmentForm.groupCheckboxesByQuestions(checkboxes);
      expect(groups).toHaveLength(0);
    });
  });

  describe('assignCheckboxIds', () => {
    test('should convert checkboxes to radio buttons with unique names per question', () => {
      const checkboxes = document.querySelectorAll('input[type="checkbox"]');
      assessmentForm.assignCheckboxIds(checkboxes);

      // Check that all inputs are now radio buttons
      const radios = document.querySelectorAll('input[type="radio"]');
      expect(radios).toHaveLength(6);

      // Check that question 1 radios have same name
      const q1Radios = document.querySelectorAll('input[name="skill-assessment-q1"]');
      expect(q1Radios).toHaveLength(3);

      // Check that question 2 radios have same name
      const q2Radios = document.querySelectorAll('input[name="skill-assessment-q2"]');
      expect(q2Radios).toHaveLength(3);

      // Check that each radio has unique ID and correct value
      expect(q1Radios[0].id).toBe('skill-assessment-q1-r1');
      expect(q1Radios[0].value).toBe('1');
      expect(q1Radios[1].id).toBe('skill-assessment-q1-r2');
      expect(q1Radios[1].value).toBe('2');
      expect(q1Radios[2].id).toBe('skill-assessment-q1-r3');
      expect(q1Radios[2].value).toBe('3');
    });

    test('should make radio buttons interactive', () => {
      const checkboxes = document.querySelectorAll('input[type="checkbox"]');
      assessmentForm.assignCheckboxIds(checkboxes);

      const radios = document.querySelectorAll('input[type="radio"]');
      radios.forEach(radio => {
        expect(radio.disabled).toBe(false);
        expect(radio.style.pointerEvents).toBe('auto');
        expect(radio.style.cursor).toBe('pointer');
        expect(radio.hasAttribute('readonly')).toBe(false);
      });
    });

    test('should create proper labels for each radio button', () => {
      const checkboxes = document.querySelectorAll('input[type="checkbox"]');
      assessmentForm.assignCheckboxIds(checkboxes);

      const labels = document.querySelectorAll('label.rating-label');
      expect(labels).toHaveLength(6);

      // Check that labels are properly associated
      expect(labels[0].getAttribute('for')).toBe('skill-assessment-q1-r1');
      expect(labels[0].textContent).toBe('Option one');
    });

    test('should handle radio button selection independently per question', () => {
      const checkboxes = document.querySelectorAll('input[type="checkbox"]');
      assessmentForm.assignCheckboxIds(checkboxes);

      // Select option 2 for question 1
      const q1Option2 = document.querySelector('input[name="skill-assessment-q1"][value="2"]');
      const q1Option2Li = q1Option2.closest('li');
      q1Option2Li.click();

      // Select option 1 for question 2
      const q2Option1 = document.querySelector('input[name="skill-assessment-q2"][value="1"]');
      const q2Option1Li = q2Option1.closest('li');
      q2Option1Li.click();

      // Verify selections are independent
      expect(q1Option2.checked).toBe(true);
      expect(q2Option1.checked).toBe(true);

      // Verify only one option selected per question
      const q1Radios = document.querySelectorAll('input[name="skill-assessment-q1"]');
      const q1CheckedCount = Array.from(q1Radios).filter(r => r.checked).length;
      expect(q1CheckedCount).toBe(1);

      const q2Radios = document.querySelectorAll('input[name="skill-assessment-q2"]');
      const q2CheckedCount = Array.from(q2Radios).filter(r => r.checked).length;
      expect(q2CheckedCount).toBe(1);
    });

    test('should store form data correctly', () => {
      const checkboxes = document.querySelectorAll('input[type="checkbox"]');
      assessmentForm.assignCheckboxIds(checkboxes);

      // Select options
      const q1Option2Li = document.querySelector('input[name="skill-assessment-q1"][value="2"]').closest('li');
      q1Option2Li.click();

      const q2Option3Li = document.querySelector('input[name="skill-assessment-q2"][value="3"]').closest('li');
      q2Option3Li.click();

      // Check that form data is stored correctly
      expect(assessmentForm.formData['skill-assessment-q1']).toBe('2');
      expect(assessmentForm.formData['skill-assessment-q2']).toBe('3');
    });
  });

  describe('radio button interaction', () => {
    test('should allow only one selection per question', () => {
      const checkboxes = document.querySelectorAll('input[type="checkbox"]');
      assessmentForm.assignCheckboxIds(checkboxes);

      const q1Option1Li = document.querySelector('input[name="skill-assessment-q1"][value="1"]').closest('li');
      const q1Option2Li = document.querySelector('input[name="skill-assessment-q1"][value="2"]').closest('li');

      // Select option 1
      q1Option1Li.click();
      expect(document.querySelector('input[name="skill-assessment-q1"][value="1"]').checked).toBe(true);
      expect(document.querySelector('input[name="skill-assessment-q1"][value="2"]').checked).toBe(false);

      // Select option 2 (should deselect option 1)
      q1Option2Li.click();
      expect(document.querySelector('input[name="skill-assessment-q1"][value="1"]').checked).toBe(false);
      expect(document.querySelector('input[name="skill-assessment-q1"][value="2"]').checked).toBe(true);
    });

    test('should apply visual feedback on selection', () => {
      const checkboxes = document.querySelectorAll('input[type="checkbox"]');
      assessmentForm.assignCheckboxIds(checkboxes);

      const q1Option1Li = document.querySelector('input[name="skill-assessment-q1"][value="1"]').closest('li');
      q1Option1Li.click();

      expect(q1Option1Li.style.backgroundColor).toBe('rgb(240, 248, 255)');
      expect(q1Option1Li.style.borderColor).toBe('rgb(0, 120, 212)');
    });
  });
});
