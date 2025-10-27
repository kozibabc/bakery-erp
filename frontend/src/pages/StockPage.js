import React, { useState, useEffect } from 'react';

function StockPage() {
  const [stock, setStock] = useState([]);

  const token = localStorage.getItem('token');

  useEffect(() => {
    fetchStock();
  }, []);

  const fetchStock = async () => {
    const res = await fetch('http://localhost:3000/api/stock', {
      headers: { Authorization: `Bearer ${token}` }
    });
    const data = await res.json();
    setStock(data);
  };

  const totalValue = stock.reduce((sum, item) => 
    sum + (parseFloat(item.qtyOnHand) * parseFloat(item.avgCost)), 0
  );

  return (
    <div>
      <div className="card">
        <h2>📊 Склад</h2>
        <p style={{color: '#666', marginTop: 10}}>
          Залишки компонентів на складі
        </p>

        <table style={{width: '100%', borderCollapse: 'collapse', marginTop: 20}}>
          <thead>
            <tr style={{background: '#f7fafc', borderBottom: '2px solid #e2e8f0'}}>
              <th style={{padding: 12, textAlign: 'left'}}>Компонент</th>
              <th style={{padding: 12, textAlign: 'left'}}>Тип</th>
              <th style={{padding: 12, textAlign: 'right'}}>Залишок</th>
              <th style={{padding: 12, textAlign: 'right'}}>Сер. ціна</th>
              <th style={{padding: 12, textAlign: 'right'}}>Вартість</th>
            </tr>
          </thead>
          <tbody>
            {stock.map(item => (
              <tr key={item.id} style={{borderBottom: '1px solid #e2e8f0'}}>
                <td style={{padding: 12}}>{item.Component?.name || '-'}</td>
                <td style={{padding: 12}}>
                  {item.Component?.type === 'RAW' && '🌾 Сировина'}
                  {item.Component?.type === 'PACK' && '📦 Упаковка'}
                </td>
                <td style={{padding: 12, textAlign: 'right'}}>
                  {parseFloat(item.qtyOnHand).toFixed(3)} {item.Component?.unit}
                </td>
                <td style={{padding: 12, textAlign: 'right'}}>
                  {parseFloat(item.avgCost).toFixed(2)} грн
                </td>
                <td style={{padding: 12, textAlign: 'right'}}>
                  <strong>
                    {(parseFloat(item.qtyOnHand) * parseFloat(item.avgCost)).toFixed(2)} грн
                  </strong>
                </td>
              </tr>
            ))}
          </tbody>
          <tfoot>
            <tr style={{background: '#f7fafc', borderTop: '2px solid #e2e8f0'}}>
              <td colSpan="4" style={{padding: 12, textAlign: 'right'}}><strong>Загальна вартість:</strong></td>
              <td style={{padding: 12, textAlign: 'right'}}>
                <strong style={{color: '#667eea', fontSize: 18}}>
                  {totalValue.toFixed(2)} грн
                </strong>
              </td>
            </tr>
          </tfoot>
        </table>

        {stock.length === 0 && (
          <p style={{textAlign: 'center', padding: 40, color: '#999'}}>
            Склад порожній. Додайте закупки!
          </p>
        )}
      </div>
    </div>
  );
}

export default StockPage;
