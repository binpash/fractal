import seaborn as sns
import seaborn.objects as so
import pandas as pd
import matplotlib.pyplot as plt
import pathlib

# Base directories
BASE_DIR = pathlib.Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / 'data'
# Store figures under timestamped sub-directory to avoid overwriting
import datetime as _dt
FIG_DIR = BASE_DIR / 'figures' / _dt.datetime.now().strftime('%Y%m%d-%H%M%S')
FIG_DIR.mkdir(parents=True, exist_ok=True)

# Helper to load csv
load = lambda name, **kwargs: pd.read_csv(DATA_DIR / name, **kwargs)

sns.set_theme(style='white', palette='deep', font="sans-serif")
sns.set_style("white", {
    "font.family": "serif",
    "font.serif": ["Georgia", "serif"]
})
sns.set_context("paper", font_scale=1.8)

deep_blue = sns.color_palette('deep')[0]
deep_green = sns.color_palette("deep")[2]
lighter_green = tuple(c * 1.4 for c in deep_green)
darker_green = tuple(c * 0.71 for c in deep_green)

##############################
# Prepare first dataset (fault-free performance)
##############################
df = load('fault_free.csv', skiprows=1)
speedup_columns = [c for c in df.columns if c.endswith('|s')]
df = df[['benchmark', 'script'] + speedup_columns]
df = pd.melt(df, id_vars=['benchmark', 'script'], value_vars=speedup_columns, var_name='variable', value_name='value')
df[['system', 'nodes', 'type']] = df['variable'].str.split('|', expand=True)
df['type'] = df['type'].map({'s': 'speedup'})
df = df[['benchmark', 'system', 'script', 'type', 'nodes', 'value']]
df = df.dropna(subset=['value'])
##############################
# Plot first dataset dist plot
##############################

fig, ax1 = plt.subplots(figsize=(9, 5))
f1 = sns.kdeplot(data=df[df['nodes'] == '30'], x='value', hue='system', common_norm=False, fill=True, alpha=0.5, linewidth=0, log_scale=True, ax=ax1)
sns.move_legend(ax1, "upper left", title='', frameon=False)
ax2 = ax1.twinx()
sns.ecdfplot(data=df[df['nodes'] == '30'], x='value', hue='system', log_scale=True, ax=ax2)
sns.move_legend(ax2, "upper left", title='', frameon=False)
ax2.set_title('30 Nodes', pad=-20, y =1)

ax1.set_xlabel('Speedup')
ax1.set_ylabel('Density (PDF)')
ax2.set_ylabel('Proportion (CDF)')
ax1.tick_params(left=False, right=False)
ax2.tick_params(left=False, right=False)
fig.tight_layout()
# handles, labels = ax1.get_legend_handles_labels()
# ax1.legend(handles, labels, title='')
# handles, labels = ax2.get_legend_handles_labels()
# ax2.legend(handles, labels, title='', frameon=False)
# ax2.legend(ax2.get_legend_handles_labels(), loc='upper left', title='', frameon=False)
fig.savefig(FIG_DIR / 'eval1dist.pdf')


##############################
# Plot first dataset violin plot
##############################
fig = sns.catplot(data=df, kind='violin', x='benchmark', y='value', hue='system', col='nodes', log_scale=True, height=6, aspect=1.66, common_norm=True, density_norm='width', dodge=True, bw_adjust=1.2)
fig.set_axis_labels('', 'Speedup')
fig.legend.set_bbox_to_anchor((0.13, 0.76))
fig.axes.flat[0].set_title('4 Nodes', pad=-8)
fig.axes.flat[1].set_title('30 Nodes', pad=-8)
fig.legend.set_title('')
fig.savefig(FIG_DIR / 'eval1violin.pdf')



# ##############################
# # Prepare second dataset
# ##############################
# df = load('fault_hard.csv', skiprows=0)
# df = pd.melt(df, id_vars=['script'], value_vars=[c for c in df.columns if c != 'script'], var_name='variable', value_name='value')
# df[['system', 'type', 'percentage']] = df['variable'].str.split('|', expand=True)
# df['percentage'] = df['percentage'].map(lambda s: s + '%')
# df['type'] = df['type'].map(lambda t: 'ahs' if t == 'fault' else t)
# df['type'] = pd.Categorical(df['type'], categories=['ahs', 'regular', 'merger'], ordered=True)

# ##############################
# # Plot second dataset (hard faults)
# ##############################
# custom_palette = [deep_blue, lighter_green, darker_green]
# fig, (ax1, bx1, ax2, bx2, ax3) = plt.subplots(1, 5, figsize=(9, 5), gridspec_kw={'wspace': 0, 'width_ratios': [10, 1, 10, 1, 10]}, sharey=True)

# # Hide bx1 and bx2
# bx1.set_visible(False)
# bx2.set_visible(False)

# sns.scatterplot(data=df[(df['script'] == 'classics/top-n.sh') & (df['percentage'] != '0%')], x='percentage', y='value', hue='type', style='type', ax=ax1, palette=custom_palette, markers=['s', 'D', 'X'], s=100)
# sns.scatterplot(data=df[(df['script'] == 'analytics/vpd.sh') & (df['percentage'] != '0%')], x='percentage', y='value', hue='type', style='type', ax=ax2, palette=custom_palette, legend=False, markers=['s', 'D', 'X'], s=100)
# sns.scatterplot(data=df[(df['script'] == 'analytics/temp.sh') & (df['percentage'] != '0%')], x='percentage', y='value', hue='type', style='type', ax=ax3, palette=custom_palette, legend=False, markers=['s', 'D', 'X'], s=100)

# ax1.set_yscale('log')
# ax2.set_yscale('log')
# ax3.set_yscale('log')

# ax1.set_xlabel('')
# ax2.set_xlabel('')
# ax3.set_xlabel('')
# ax1.set_ylabel('Time (s)')

# ax1.axhline(y=df[(df['percentage'] == '0%') & (df['system'] == 'fractal') & (df['script'] == 'classics/top-n.sh')]['value'].values[0], color=deep_green, linestyle='--')
# ax1.annotate('fractal', xy=(0.13, df[(df['percentage'] == '0%') & (df['system'] == 'fractal') & (df['script'] == 'classics/top-n.sh')]['value'].values[0] + 10))

# ax1.axhline(y=df[(df['percentage'] == '0%') & (df['system'] == 'ahs') & (df['script'] == 'classics/top-n.sh')]['value'].values[0], color=deep_blue, linestyle='--')
# ax1.annotate('ahs', xy=(0.13, df[(df['percentage'] == '0%') & (df['system'] == 'ahs') & (df['script'] == 'classics/top-n.sh')]['value'].values[0] + 30))

# ax2.axhline(y=df[(df['percentage'] == '0%') & (df['system'] == 'fractal') & (df['script'] == 'analytics/vpd.sh')]['value'].values[0], color=deep_green, linestyle='--')
# ax2.annotate('fractal', xy=(0.13, df[(df['percentage'] == '0%') & (df['system'] == 'fractal') & (df['script'] == 'analytics/vpd.sh')]['value'].values[0] + 2))

# ax2.axhline(y=df[(df['percentage'] == '0%') & (df['system'] == 'ahs') & (df['script'] == 'analytics/vpd.sh')]['value'].values[0], color=deep_blue, linestyle='--')
# ax2.annotate('ahs', xy=(0.13, df[(df['percentage'] == '0%') & (df['system'] == 'ahs') & (df['script'] == 'analytics/vpd.sh')]['value'].values[0] + 35))

# ax3.axhline(y=df[(df['percentage'] == '0%') & (df['system'] == 'fractal') & (df['script'] == 'analytics/temp.sh')]['value'].values[0], color=deep_green, linestyle='--')
# ax3.annotate('fractal', xy=(0.13, df[(df['percentage'] == '0%') & (df['system'] == 'fractal') & (df['script'] == 'analytics/temp.sh')]['value'].values[0] + 4))

# ax3.axhline(y=df[(df['percentage'] == '0%') & (df['system'] == 'ahs') & (df['script'] == 'analytics/temp.sh')]['value'].values[0], color=deep_blue, linestyle='--')
# ax3.annotate('ahs', xy=(0.13, df[(df['percentage'] == '0%') & (df['system'] == 'ahs') & (df['script'] == 'analytics/temp.sh')]['value'].values[0] + 50))

# ax1.set_title('classics/top-n.sh')
# ax2.set_title('analytics/vpd.sh')
# ax3.set_title('analytics/temp.sh')

# # map legend labels
# handles, _ = ax1.get_legend_handles_labels()
# ax1.legend(handles, ['ahs fault', 'regular fault', 'merger fault'])
# sns.move_legend(ax1, "lower left", title='', frameon=False, bbox_to_anchor=(-0.09, -0.03))
# # ax1.get_legend().get_frame().set_linewidth(0.0)
# # Remove lbox surrounding legend

# fig.text(0.5, 0.03, "% completion of total execution", ha='center', va='center')

# fig.tight_layout()
# fig.subplots_adjust(bottom=0.13)
# fig.savefig(FIG_DIR / 'eval2scatter.pdf')


# ##############################
# # Prepare third dataset
# ##############################
df = load('fault_soft.csv', skiprows=1)
df = pd.melt(df, id_vars=['benchmark', 'script'], value_vars=[c for c in df.columns if c[-1].isdigit()], var_name='variable', value_name='value')
df[['system', 'nodes']] = df['variable'].str.split('|', expand=True)
df = df.dropna(subset=['value'])
df = df[df['system'] != 'dish']
df['system'] = df['system'].map({'fractal': 'no fault', 'fractal-r': 'regular-node fault', 'fractal-m': 'merger-node fault'})
df = df[['benchmark', 'system', 'script', 'nodes', 'value']]
df['system'] = pd.Categorical(df['system'], categories=['no fault', 'regular-node fault', 'merger-node fault'], ordered=True)

##############################
# Plot third dataset violin plot (soft faults)
##############################
green_palette = [lighter_green, deep_green, darker_green]
fig = sns.catplot(data=df, kind='violin', x='benchmark', y='value', hue='system', col='nodes', log_scale=True, height=6, aspect=0.75, common_norm=True, density_norm='width', dodge=True, bw_adjust=1.2, palette=green_palette)
fig.set_axis_labels('', 'Time (s)')
fig.axes.flat[0].set_title('4 Nodes', pad=-10)
fig.axes.flat[1].set_title('30 Nodes', pad=-10)
fig.legend.set_title('')
# fig.legend.set_bbox_to_anchor((0.33, 0.17))
fig.legend.set_bbox_to_anchor((0.74, 0.72))
fig.savefig(FIG_DIR / 'eval3violin.pdf')

# ##############################
# # Prepare fourth dataset (microbench)
# ##############################
# df = load('microbench.csv', skiprows=1)
# df = pd.melt(df, id_vars=['benchmark', 'script'], value_vars=['enabled', 'disabled', 'dynamic'], var_name='mode', value_name='value')

# ##############################
# # Plot fourth dataset
# ##############################
# fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(9, 5), gridspec_kw={'width_ratios': [22, 5], 'wspace': 0})
# ax2.set_yticks([])
# ax2.set_xlabel('Analytics')
# ax2 = ax2.twinx()

# # markers=[[(0, 0), (0, 1), (0.866, -0.5)], [(0, 0), (0, 1), (-0.866, -0.5)], [(0, 0), (-0.866, -0.5), (0.866, -0.5)]]
# sns.scatterplot(data=df[df['benchmark'] == 'NLP'], x='script', y='value', hue='mode', style='mode', palette='deep', markers=['s', 'D', 'X'], s=50, ax=ax1, alpha=1)
# sns.scatterplot(data=df[df['benchmark'] == 'Analytics'], x='script', y='value', hue='mode', style='mode', palette='deep', ax=ax2, alpha=1, s=50, markers=['s', 'D', 'X'], legend=False)

# sns.move_legend(ax1, "upper left", title='', frameon=False, bbox_to_anchor=(-0.02, 0.99))

# ax1.set_yscale('log')
# ax2.set_yscale('log')

# ax1.set_xticklabels([])
# ax2.set_xticklabels([])

# ax1.set_xlabel('NLP')
# ax1.set_ylabel('Time (s)')
# ax2.set_ylabel('Time (s)')

# fig.tight_layout()
# fig.savefig(FIG_DIR / 'eval4scatter.pdf')
