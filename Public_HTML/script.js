// Always start at the hero on refresh (don't restore previous scroll position).
if ('scrollRestoration' in history) history.scrollRestoration = 'manual';
window.scrollTo(0, 0);

// LOAD SCREEN — hide after the logo assembly animation completes.
// Total animation: ~3.15s; brief settle, then 1.0s fade.
const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
const LOAD_DURATION = reduceMotion ? 200 : 5925;

// Note: overflow stays unlocked during the load animation so the scrollbar is visible
// (no layout shift when the page reveals). Wheel events are still blocked from causing
// native scroll because the smooth-snap wheel handler preventDefaults at its top.

window.addEventListener('load', () => {
  setTimeout(() => {
    document.getElementById('loadScreen')?.classList.add('is-done');
    document.body.classList.add('is-loaded');
  }, LOAD_DURATION);
});

// CURSOR GLOW — soft warm halo follows the pointer with gentle lag.
(function initCursorGlow() {
  if (window.matchMedia('(hover: none)').matches) return;
  const glow = document.getElementById('cursorGlow');
  if (!glow) return;

  let mx = window.innerWidth / 2;
  let my = window.innerHeight / 2;
  let gx = mx, gy = my;

  window.addEventListener('mousemove', (e) => {
    mx = e.clientX;
    my = e.clientY;
  }, { passive: true });

  function tick() {
    gx += (mx - gx) * 0.12;
    gy += (my - gy) * 0.12;
    glow.style.transform = `translate3d(${gx}px, ${gy}px, 0)`;
    requestAnimationFrame(tick);
  }
  tick();
})();

// SCROLL REVEAL — add 'in-view' to each scene as it enters.
(function initScrollReveal() {
  const scenes = document.querySelectorAll('.scene');
  if (!scenes.length) return;

  if (!('IntersectionObserver' in window)) {
    scenes.forEach(s => s.classList.add('in-view'));
    return;
  }

  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('in-view');
        observer.unobserve(entry.target);
      }
    });
  }, { threshold: 0.18, rootMargin: '0px 0px -10% 0px' });

  scenes.forEach(s => observer.observe(s));
})();

// MENU DRAWER — open / close, close on link click or Esc.
(function initMenu() {
  const toggle = document.getElementById('menuToggle');
  const drawer = document.getElementById('menuDrawer');
  if (!toggle || !drawer) return;

  function setOpen(open) {
    toggle.setAttribute('aria-expanded', String(open));
    drawer.classList.toggle('is-open', open);
    drawer.setAttribute('aria-hidden', String(!open));
    document.body.style.overflow = open ? 'hidden' : '';
  }

  toggle.addEventListener('click', () => {
    const isOpen = toggle.getAttribute('aria-expanded') === 'true';
    setOpen(!isOpen);
  });

  drawer.querySelectorAll('a[href^="#"]').forEach(link => {
    link.addEventListener('click', () => setOpen(false));
  });

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && drawer.classList.contains('is-open')) setOpen(false);
  });
})();

// HERO PHOTOS — chronological cross-fade with a slow Ken-Burns scale.
(function initHeroPhotos() {
  const photos = document.querySelectorAll('.hero-photo');
  if (photos.length < 2) return;

  const INTERVAL = 2750; // ms per photo
  let activeIndex = 0;

  setInterval(() => {
    const nextIndex = (activeIndex + 1) % photos.length;
    photos[nextIndex].classList.add('is-active');
    photos[activeIndex].classList.remove('is-active');
    activeIndex = nextIndex;
  }, INTERVAL);
})();

// LOGO THEME — auto-swap header logo variant based on the scene currently in view.
// rootMargin trick: only the scene crossing the viewport mid-line "intersects".
(function initLogoTheme() {
  if (!('IntersectionObserver' in window)) return;

  const sceneThemes = {
    hero:     'dark',
    about:    'light',
    work:     'dark',
    services: 'light',
    contact:  'dark'
  };

  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        const theme = sceneThemes[entry.target.id];
        if (theme) document.body.dataset.theme = theme;
      }
    });
  }, { threshold: 0, rootMargin: '-50% 0px -50% 0px' });

  document.querySelectorAll('.scene').forEach(s => observer.observe(s));
})();

// SMOOTH SNAP — slow, eased section snap on desktop. Replaces native CSS snap
// on hover-capable devices for a flowing feel. Touch keeps CSS proximity snap.
(function initSmoothSnap() {
  if (!window.matchMedia('(hover: hover) and (pointer: fine)').matches) return;
  if (reduceMotion) return;

  const scenes = Array.from(document.querySelectorAll('.scene'));
  if (!scenes.length) return;

  // JS owns snap timing now — turn off CSS snap so they don't fight.
  document.documentElement.style.scrollSnapType = 'none';
  // Disable CSS scroll-behavior:smooth so per-frame scrollTo calls don't queue smooth animations.
  document.documentElement.style.scrollBehavior = 'auto';

  const SNAP_DURATION = 900;     // ms — flow duration between sections
  const WHEEL_DEBOUNCE = 850;    // ms before another wheel input can trigger
  let isAnimating = false;
  let lastWheelTime = 0;

  function easeInOutCubic(t) {
    return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;
  }

  function currentIndex() {
    const center = window.scrollY + window.innerHeight / 2;
    let best = 0, bestDist = Infinity;
    scenes.forEach((scene, idx) => {
      const sceneCenter = scene.offsetTop + scene.offsetHeight / 2;
      const dist = Math.abs(center - sceneCenter);
      if (dist < bestDist) { bestDist = dist; best = idx; }
    });
    return best;
  }

  function snapTo(index) {
    if (index < 0 || index >= scenes.length || isAnimating) return;
    isAnimating = true;
    const start = window.scrollY;
    const dist = scenes[index].offsetTop - start;
    const t0 = performance.now();

    function step(now) {
      const t = Math.min((now - t0) / SNAP_DURATION, 1);
      window.scrollTo(0, start + dist * easeInOutCubic(t));
      if (t < 1) requestAnimationFrame(step);
      else { isAnimating = false; }
      // Note: lastWheelTime is NOT reset here. Debounce only counts from the
      // initial wheel that fired the snap, so after the snap completes the user
      // can immediately fire the next one (no extra wait period).
    }
    requestAnimationFrame(step);
  }

  // Wheel + trackpad — always block native scroll first so there's no "hesitation"
  // before our snap kicks in (browser was getting a few pixels of native scroll
  // through small-deltaY events that didn't pass our threshold).
  window.addEventListener('wheel', (e) => {
    e.preventDefault();
    if (Math.abs(e.deltaY) < 1) return; // tiny inertia events still ignored
    if (isAnimating) return;
    const now = Date.now();
    if (now - lastWheelTime < WHEEL_DEBOUNCE) return;
    lastWheelTime = now;
    snapTo(currentIndex() + (e.deltaY > 0 ? 1 : -1));
  }, { passive: false });

  // Keyboard
  window.addEventListener('keydown', (e) => {
    if (isAnimating) return;
    const idx = currentIndex();
    let target = -1;
    if (e.key === 'ArrowDown' || e.key === 'PageDown' || e.key === ' ') target = idx + 1;
    else if (e.key === 'ArrowUp' || e.key === 'PageUp') target = idx - 1;
    else if (e.key === 'Home') target = 0;
    else if (e.key === 'End') target = scenes.length - 1;
    if (target >= 0) { e.preventDefault(); snapTo(target); }
  });

  // Anchor links (menu drawer + in-page) use the same eased animation
  document.querySelectorAll('a[href^="#"]').forEach(link => {
    link.addEventListener('click', (e) => {
      const id = link.getAttribute('href').slice(1);
      if (!id) return;
      const target = document.getElementById(id);
      if (!target) return;
      const idx = scenes.indexOf(target);
      if (idx >= 0) {
        e.preventDefault();
        snapTo(idx);
      }
    });
  });
})();
