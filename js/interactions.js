/**
 * JAB Systems - Interactions
 * Modal popups for Coming Soon tools with fun facts
 */

// Fun facts for each tool
const toolFacts = {
  'network-monitor': [
    'Network Monitor can analyze over 50,000 packets per second.',
    'Built with zero external dependencies for maximum reliability.',
    'Supports custom alerting rules with webhook integrations.',
    'Real-time visualization of traffic patterns across your entire infrastructure.'
  ],
  'log-analyzer': [
    'Log Analyzer uses pattern matching to detect anomalies automatically.',
    'Can process and index 1 million log lines in under 10 seconds.',
    'Supports over 50 common log formats out of the box.',
    'Intelligent correlation engine links related events across systems.'
  ],
  'default': [
    'Every JAB tool is built for production-grade reliability.',
    'All modules can be repositioned via drag-and-drop.',
    'Themes are fully customizable to match your environment.',
    'Built by operators, for operators.'
  ]
};

// Get a random fact for a tool
function getRandomFact(toolId) {
  const facts = toolFacts[toolId] || toolFacts['default'];
  return facts[Math.floor(Math.random() * facts.length)];
}

// Open modal with tool info
function openModal(cardElement) {
  const toolId = cardElement.getAttribute('data-tool');
  const toolTitle = cardElement.querySelector('.tool-card__title').textContent;

  const backdrop = document.getElementById('modal-backdrop');
  const titleEl = document.getElementById('modal-title');
  const factEl = document.getElementById('modal-fact');

  titleEl.textContent = toolTitle;
  factEl.textContent = getRandomFact(toolId);

  backdrop.classList.add('active');
  document.body.style.overflow = 'hidden';
}

// Close modal
function closeModal(event) {
  // If called from backdrop click, only close if clicking the backdrop itself
  if (event && event.target !== event.currentTarget) return;

  const backdrop = document.getElementById('modal-backdrop');
  backdrop.classList.remove('active');
  document.body.style.overflow = '';
}

// Keyboard support
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    closeModal();
    closeContactModal();
  }
});

// ============ CONTACT FORM MODAL ============

// Open contact modal
function openContactModal(preselectedTool) {
  const modal = document.getElementById('contact-modal');
  if (!modal) return;

  // Reset form state
  const form = document.getElementById('contact-form');
  const successMessage = document.getElementById('form-success');
  if (form) {
    form.style.display = 'flex';
    form.reset();
  }
  if (successMessage) {
    successMessage.style.display = 'none';
  }

  // Pre-select tool if specified
  if (preselectedTool) {
    const interestSelect = document.getElementById('interest');
    if (interestSelect) {
      interestSelect.value = preselectedTool;
    }
  }

  modal.classList.add('active');
  document.body.style.overflow = 'hidden';

  // Focus first input
  setTimeout(() => {
    const firstInput = modal.querySelector('input[type="text"]');
    if (firstInput) firstInput.focus();
  }, 100);
}

// Close contact modal
function closeContactModal(event) {
  if (event && event.target !== event.currentTarget) return;

  const modal = document.getElementById('contact-modal');
  if (modal) {
    modal.classList.remove('active');
    document.body.style.overflow = '';
  }
}

// Handle contact form submission
document.addEventListener('DOMContentLoaded', () => {
  const form = document.getElementById('contact-form');
  if (form) {
    form.addEventListener('submit', async (e) => {
      e.preventDefault();

      const submitBtn = form.querySelector('.form-submit');
      const originalText = submitBtn.textContent;
      submitBtn.textContent = 'Sending...';
      submitBtn.disabled = true;

      try {
        const formData = new FormData(form);
        const response = await fetch('/', {
          method: 'POST',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          body: new URLSearchParams(formData).toString()
        });

        if (response.ok) {
          // Show success message
          form.style.display = 'none';
          const successMessage = document.getElementById('form-success');
          if (successMessage) {
            successMessage.style.display = 'block';
          }
        } else {
          throw new Error('Form submission failed');
        }
      } catch (error) {
        console.error('Form error:', error);
        alert('There was an error submitting the form. Please try again.');
        submitBtn.textContent = originalText;
        submitBtn.disabled = false;
      }
    });
  }
});

// DOM ready initialization
document.addEventListener('DOMContentLoaded', () => {
  // Add smooth entrance animation to cards on page load
  const cards = document.querySelectorAll('.tool-card');
  cards.forEach((card, index) => {
    card.style.opacity = '0';
    card.style.transform = 'translateY(20px)';

    setTimeout(() => {
      card.style.transition = 'opacity 0.4s ease, transform 0.4s ease';
      card.style.opacity = '';
      card.style.transform = '';
    }, 100 + (index * 100));
  });

  // Scroll indicator - hide after scrolling
  const scrollIndicator = document.querySelector('.scroll-indicator');
  if (scrollIndicator) {
    let hasScrolled = false;
    window.addEventListener('scroll', () => {
      if (!hasScrolled && window.scrollY > 100) {
        hasScrolled = true;
        scrollIndicator.style.opacity = '0';
        scrollIndicator.style.transition = 'opacity 0.3s ease';
      }
    }, { passive: true });
  }
});
