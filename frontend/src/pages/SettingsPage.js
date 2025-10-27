import React, { useState, useEffect } from 'react';

function SettingsPage() {
  const [settings, setSettings] = useState({
    wholesaleMarkup: 10,
    retail1Markup: 40,
    retail2Markup: 70,
    laborCostPercent: 10,
    overheadPercent: 5,
    companyName: 'Sazhenko Bakery'
  });

  const token = localStorage.getItem('token');

  useEffect(() => {
    fetchSettings();
  }, []);

  const fetchSettings = async () => {
    const res = await fetch('http://localhost:3000/api/settings', {
      headers: { Authorization: `Bearer ${token}` }
    });
    const data = await res.json();
    setSettings(data);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    await fetch('http://localhost:3000/api/settings', {
      method: 'PUT',
      headers: { 
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`
      },
      body: JSON.stringify(settings)
    });
    alert('Налаштування збережено! Ціни товарів будуть перераховані.');
    fetchSettings();
  };

  return (
    <div>
      <div className="card">
        <h2>⚙️ Налаштування</h2>
        <p style={{color: '#666', marginTop: 10}}>
          Конфігурація системи ціноутворення
        </p>

        <form onSubmit={handleSubmit} style={{marginTop: 20}}>
          <div style={{marginBottom: 20}}>
            <h3>Наценки (%)</h3>
            <div style={{display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 15, marginTop: 10}}>
              <div>
                <label>Опт</label>
                <input 
                  type="number"
                  step="0.01"
                  value={settings.wholesaleMarkup} 
                  onChange={e => setSettings({...settings, wholesaleMarkup: e.target.value})} 
                />
              </div>
              <div>
                <label>Роздріб 1</label>
                <input 
                  type="number"
                  step="0.01"
                  value={settings.retail1Markup} 
                  onChange={e => setSettings({...settings, retail1Markup: e.target.value})} 
                />
              </div>
              <div>
                <label>Роздріб 2</label>
                <input 
                  type="number"
                  step="0.01"
                  value={settings.retail2Markup} 
                  onChange={e => setSettings({...settings, retail2Markup: e.target.value})} 
                />
              </div>
            </div>
          </div>

          <div style={{marginBottom: 20}}>
            <h3>Накладні витрати (%)</h3>
            <div style={{display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 15, marginTop: 10}}>
              <div>
                <label>Праця</label>
                <input 
                  type="number"
                  step="0.01"
                  value={settings.laborCostPercent} 
                  onChange={e => setSettings({...settings, laborCostPercent: e.target.value})} 
                />
              </div>
              <div>
                <label>Інші витрати</label>
                <input 
                  type="number"
                  step="0.01"
                  value={settings.overheadPercent} 
                  onChange={e => setSettings({...settings, overheadPercent: e.target.value})} 
                />
              </div>
            </div>
          </div>

          <div style={{marginBottom: 20}}>
            <h3>Компанія</h3>
            <div style={{marginTop: 10}}>
              <label>Назва</label>
              <input 
                value={settings.companyName} 
                onChange={e => setSettings({...settings, companyName: e.target.value})} 
              />
            </div>
          </div>

          <button type="submit" className="btn btn-primary">
            Зберегти налаштування
          </button>
        </form>

        <div style={{marginTop: 30, padding: 20, background: '#f7fafc', borderRadius: 8}}>
          <h3>📊 Як працює ціноутворення</h3>
          <ul style={{marginTop: 10, lineHeight: 2}}>
            <li>Собівартість рецепту = Σ (компонент × ціна зі складу)</li>
            <li>Собівартість коробки = собівартість рецепту × вага × (1 + накладні%)</li>
            <li>Ціна продажу = собівартість × (1 + наценка%)</li>
            <li>Усі ціни оновлюються автоматично</li>
          </ul>
        </div>
      </div>
    </div>
  );
}

export default SettingsPage;
