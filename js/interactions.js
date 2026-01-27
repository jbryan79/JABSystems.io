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
