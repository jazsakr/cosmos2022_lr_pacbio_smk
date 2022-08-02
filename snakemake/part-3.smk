# set reference names:
ref_fa_name = config['reference']['mouse']['fa_name'],
ref_gtf_name = config['reference']['mouse']['gtf_name']

# set experiment and talon database name:
exp = config['experiment']
t_label1 = '_talon'
t_label2 = '_talon-list.csv'
talon_db_name = exp + t_label1
talon_list_name = exp + t_label2

rule all:
	input:
		expand( config['talon']['talon_ab'], exp=exp ),
		expand( config['talon']['talon_ab_f'], exp=exp),
		expand( config['talon']['talon_gtf'], exp=exp)

rule talon_abundance:
	input:
		talon = config['packages']['talon'],
		talon_db = config['talon']['talon_db'],
		talon_ra = config['talon']['talon_read_annot']
	output: 
		talon_ab = config['talon']['talon_ab']
	threads: 16
	resources:
		mem_gb = 32
	conda: 
		'envs/talon.yaml'
	shell: 
		'talon_abundance \
		--db {input.talon_db} \
		-a {ref_gtf_name} \
		-b {ref_fa_name} \
		--o ./data/{exp}/{exp}'

rule talon_filter_list:
	input:
		talon = config['packages']['talon'],
		talon_db = config['talon']['talon_db']
	output: 
		talon_list = config['talon']['talon_list']
	threads: 16
	resources:
		mem_gb = 32
	conda: 
		'envs/talon.yaml'
	shell:
		'talon_filter_transcripts \
		--db {input.talon_db} \
		-a {ref_gtf_name} \
		--maxFracA=0.5 \
		--minCount=5 \
		--minDatasets=2 \
		--o ./data/{exp}/{talon_list_name}'

rule talon_filtered_abundance:
	input:
		talon = config['packages']['talon'],
		talon_db = config['talon']['talon_db'],
		talon_list = config['talon']['talon_list']
	output: 
		talon_af = config['talon']['talon_ab_f']
	threads: 16
	resources:
		mem_gb = 32
	conda: 
		'envs/talon.yaml'
	shell: 
		'talon_abundance \
		--db {input.talon_db} \
		-a {ref_gtf_name} \
		-b {ref_fa_name} \
		--whitelist {input.talon_list} \
		--o ./data/{exp}/{exp}'

rule talon_create_gtf:
	input:
		talon = config['packages']['talon'],
		talon_db = config['talon']['talon_db'],
		talon_list = config['talon']['talon_list']
	output: 
		talon_gtf = config['talon']['talon_gtf']
	threads: 16
	resources:
		mem_gb = 32
	conda: 
		'envs/talon.yaml'
	shell: 
		'talon_create_GTF \
		--db {input.talon_db} \
		-a {ref_gtf_name} \
		-b {ref_fa_name} \
		--whitelist {input.talon_list} \
		--observed \
		--o ./data/{exp}/{exp}'