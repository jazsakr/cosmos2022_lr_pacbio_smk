import pandas as pd
from snakemake.io import expand

metadata = pd.read_csv("samples.csv", sep=',')
metadata_df = pd.DataFrame(data = metadata)
sn_list = metadata_df['sample_file_name'].tolist()

metadata_df1 = metadata_df[['sample_name', 'description', 'platform']]
metadata_df1 = metadata_df1.assign(path_file=expand(snakemake.config['sample']['labeled'], samplename=sn_list))

exp= snakemake.config['experiment']
save_path= './data/'+ exp + '/' + exp + '_talon_config.csv'

metadata_df1.to_csv(save_path, sep=',', header=False, index=False)