/* dashboard.js — Chart.js v4 renderer for AI SBOM Dashboard
   - Renders: Severity pie + Top packages bar
   - Safe with missing/empty data
   - Destroys old charts before re-render to avoid duplicates
*/
(function () {
  'use strict';

  // ---- Utilities & constants -------------------------------------------------
  const SEVERITY_ORDER = ['critical', 'high', 'medium', 'low', 'unknown'];
  const SEVERITY_LABELS = {
    critical: 'Critical',
    high: 'High',
    medium: 'Medium',
    low: 'Low',
    unknown: 'Unknown',
  };

  // Colors chosen for good contrast on dark UI
  const SEVERITY_COLORS = {
    critical: 'rgba(211, 47, 47, 0.85)',
    high: 'rgba(245, 124, 0, 0.85)',
    medium: 'rgba(251, 192, 45, 0.85)',
    low: 'rgba(56, 142, 60, 0.85)',
    unknown: 'rgba(96, 125, 139, 0.85)',
  };
  const SEVERITY_BORDERS = {
    critical: 'rgba(211, 47, 47, 1)',
    high: 'rgba(245, 124, 0, 1)',
    medium: 'rgba(251, 192, 45, 1)',
    low: 'rgba(56, 142, 60, 1)',
    unknown: 'rgba(96, 125, 139, 1)',
  };

  function hasChartJs() {
    return typeof Chart !== 'undefined' && Chart && Chart.defaults;
  }

  function normalizeSummary(s) {
    const empty = { total: 0, severity_counts: {}, top_packages: [] };
    s = s && typeof s === 'object' ? s : empty;
    const sev = Object.assign(
      { critical: 0, high: 0, medium: 0, low: 0, unknown: 0 },
      s.severity_counts || {}
    );
    const pkg = Array.isArray(s.top_packages) ? s.top_packages : [];
    return {
      total: Number(s.total || 0),
      severity_counts: sev,
      top_packages: pkg,
    };
  }

  // Keep references to destroy on re-render
  const charts = {};
  function destroyIfExists(key) {
    if (charts[key] && typeof charts[key].destroy === 'function') {
      charts[key].destroy();
      charts[key] = null;
    }
  }

  // ---- Renderers -------------------------------------------------------------

  function renderSeverityChart(summary) {
    const canvas = document.getElementById('severityChart');
    if (!canvas || !hasChartJs()) return;

    const labels = [];
    const values = [];
    const bg = [];
    const border = [];

    SEVERITY_ORDER.forEach((k) => {
      const val = Number(summary.severity_counts[k] || 0);
      labels.push(SEVERITY_LABELS[k]);
      values.push(val);
      bg.push(SEVERITY_COLORS[k]);
      border.push(SEVERITY_BORDERS[k]);
    });

    destroyIfExists('severity');

    charts.severity = new Chart(canvas.getContext('2d'), {
      type: 'pie',
      data: {
        labels,
        datasets: [{
          data: values,
          backgroundColor: bg,
          borderColor: border,
          borderWidth: 1
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,   
        aspectRatio: 1.4,             
        layout: { padding: 10 },
        plugins: {
          legend: {
            position: 'bottom',
            labels: { color: '#e3e8f5', boxWidth: 14 }
          },
          tooltip: {
            callbacks: {
              label: ctx => {
                const val = ctx.raw || 0;
                const total = values.reduce((a,b)=>a+b,0) || 1;
                const pct = ((val*100)/total).toFixed(1);
                return `${ctx.label}: ${val} (${pct}%)`;
              }
            }
          }
        }
      }
    });

  }

  function renderTopPackagesChart(summary) {
    const canvas = document.getElementById('topPackagesChart');
    if (!canvas || !hasChartJs()) return;

    // labels: package name, data: risk score
    const labels = summary.top_packages.map((x) => x.package || 'unknown');
    const data = summary.top_packages.map((x) => Number(x.score || 0));

    destroyIfExists('topPackages');

    charts.topPackages = new Chart(canvas.getContext('2d'), {
      type: 'bar',
      data: {
        labels,
        datasets: [
          {
            label: 'Risk score',
            data,
            backgroundColor: data.map((_, i) => {
              const pal = [
                SEVERITY_COLORS.critical,
                SEVERITY_COLORS.high,
                SEVERITY_COLORS.medium,
                SEVERITY_COLORS.low,
                SEVERITY_COLORS.unknown,
              ];
              return pal[i % pal.length];
            }),
            borderColor: data.map((_, i) => {
              const pal = [
                SEVERITY_BORDERS.critical,
                SEVERITY_BORDERS.high,
                SEVERITY_BORDERS.medium,
                SEVERITY_BORDERS.low,
                SEVERITY_BORDERS.unknown,
              ];
              return pal[i % pal.length];
            }),
            borderWidth: 1,
          },
        ],
      },
      options: {
        indexAxis: 'x',
        maintainAspectRatio: false,
        aspectRatio: 2,
        scales: {
          x: {
            ticks: {
              maxRotation: 45,
              callback: function (val, idx) {
                const label = labels[idx] || '';
                return label.length > 18 ? label.slice(0, 16) + '…' : label;
              },
            },
          },
          y: {
            beginAtZero: true,
            ticks: { precision: 0 },
          },
        },
        plugins: {
          legend: { display: false },
          tooltip: {
            callbacks: {
              title: (items) => items[0]?.label || '',
              label: (ctx) => `Score: ${ctx.raw}`,
            },
          },
        },
      },
    });
  }

  // ---- Public API ------------------------------------------------------------
  function renderCharts(summary) {
    const s = normalizeSummary(summary);
    renderSeverityChart(s);
    renderTopPackagesChart(s);
    // Expose for debugging if needed
    window.__SBOM_CHARTS__ = charts;
  }

  // Expose function used by dashboard.html
  window.renderCharts = renderCharts;
})();
