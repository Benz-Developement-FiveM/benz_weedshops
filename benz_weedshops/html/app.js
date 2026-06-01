const app = document.getElementById('app');
const title = document.getElementById('title');
const subtitle = document.getElementById('subtitle');
const menuView = document.getElementById('menuView');
const promptView = document.getElementById('promptView');
const optionsBox = document.getElementById('options');
const fieldsBox = document.getElementById('fields');
const backBtn = document.getElementById('backBtn');
const closeBtn = document.getElementById('closeBtn');
const cancelPrompt = document.getElementById('cancelPrompt');

let currentMenu = null;
let currentPromptFields = [];

function post(name, data = {}) {
  return fetch(`https://${GetParentResourceName()}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data)
  }).catch(() => {});
}

function closeUI() {
  app.classList.add('hidden');
  currentMenu = null;
  currentPromptFields = [];
  fieldsBox.innerHTML = '';
}

function openBase(data) {
  app.classList.remove('hidden');
  title.textContent = data.title || 'Weed Factory';
  subtitle.textContent = data.subtitle || '';
}

function openMenu(data) {
  currentMenu = data;
  openBase(data);
  menuView.classList.remove('hidden');
  promptView.classList.add('hidden');
  optionsBox.innerHTML = '';
  (data.options || []).forEach((opt) => {
    const row = document.createElement('div');
    row.className = 'option' + (opt.disabled ? ' disabled' : '');
    row.innerHTML = `
      <div class="optIcon"><i class="${opt.icon || 'fa-solid fa-circle'}"></i></div>
      <div class="optBody">
        <div class="optTitle"></div>
        <div class="optDesc"></div>
      </div>
      ${opt.arrow ? '<div class="arrow"><i class="fa-solid fa-chevron-right"></i></div>' : ''}
    `;
    row.querySelector('.optTitle').textContent = opt.title || 'Option';
    row.querySelector('.optDesc').textContent = opt.description || '';
    row.onclick = () => {
      if (opt.disabled) return;
      post('wfSelect', { id: data.id, index: opt.index });
    };
    optionsBox.appendChild(row);
  });
}

function openPrompt(data) {
  currentPromptFields = data.fields || [];
  openBase({ title: data.title || 'Input', subtitle: 'Fill out the fields below' });
  menuView.classList.add('hidden');
  promptView.classList.remove('hidden');
  fieldsBox.innerHTML = '';

  currentPromptFields.forEach((field) => {
    const wrap = document.createElement('div');
    wrap.className = 'field';
    const label = document.createElement('label');
    label.textContent = field.label || 'Field';
    wrap.appendChild(label);

    let input;
    if (field.type === 'select' && Array.isArray(field.options)) {
      input = document.createElement('select');
      field.options.forEach((opt) => {
        const o = document.createElement('option');
        o.value = opt.value ?? opt.label ?? '';
        o.textContent = opt.label ?? opt.value ?? '';
        input.appendChild(o);
      });
    } else if (field.type === 'textarea') {
      input = document.createElement('textarea');
      input.rows = 3;
    } else {
      input = document.createElement('input');
      if (field.type === 'number') input.type = 'number';
      else if (field.type === 'checkbox') input.type = 'checkbox';
      else input.type = 'text';
      if (field.min !== undefined) input.min = field.min;
      if (field.max !== undefined) input.max = field.max;
      if (field.type === 'checkbox' && (field.default === true || field.checked === true)) input.checked = true;
    }

    input.dataset.index = field.index;
    input.dataset.type = field.type || 'input';
    input.required = !!field.required;
    input.placeholder = field.placeholder || '';
    if (field.default !== undefined && field.default !== null) input.value = field.default;
    wrap.appendChild(input);

    if (field.description) {
      const help = document.createElement('div');
      help.className = 'help';
      help.textContent = field.description;
      wrap.appendChild(help);
    }
    fieldsBox.appendChild(wrap);
  });
}

window.addEventListener('message', (event) => {
  const data = event.data || {};
  if (data.action === 'openMenu') openMenu(data);
  if (data.action === 'openPrompt') openPrompt(data);
  if (data.action === 'close') closeUI();
});

backBtn.onclick = () => post('wfBack', { parent: currentMenu?.parent });
closeBtn.onclick = () => post('wfClose');
cancelPrompt.onclick = () => { closeUI(); post('wfPromptCancel'); };

promptView.addEventListener('submit', (e) => {
  e.preventDefault();
  const values = [...fieldsBox.querySelectorAll('input, select, textarea')].map((input) => ({
    index: Number(input.dataset.index),
    type: input.dataset.type,
    value: input.type === 'checkbox' ? input.checked : input.value
  }));
  post('wfPromptSubmit', { values });
});

document.addEventListener('keyup', (e) => {
  if (e.key === 'Escape') post('wfClose');
});


document.addEventListener('visibilitychange', () => {
  if (document.hidden) closeUI();
});
