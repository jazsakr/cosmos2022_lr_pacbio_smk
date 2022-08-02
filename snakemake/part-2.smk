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
		expand( config['talon']['talon_read_annot'], exp=exp )

rule talon_config:
	output:
		talon_config = config['talon']['talon_config']
	threads: 1
	resources:
		mem_gb = 4
	script:
		'scripts/talon_config.py'

rule talon_db:
	input:
		talon = config['packages']['talon'],
		ref_gtf = config['reference']['mouse']['gtf']
	output:
		db = config['talon']['talon_db']
	threads: 16
	resources:
		mem_gb = 32
	conda: 
		'envs/talon.yaml'
	shell: 
		'talon_initialize_database \
    	--f {input.ref_gtf} \
    	--g {ref_fa_name} \
    	--a {ref_gtf_name} \
    	--l 0 \
    	--idprefix TALONT \
    	--5p 500 \
    	--3p 300 \
    	--o ./data/{exp}/{talon_db_name}'

rule talon:
	input:
		talon = config['packages']['talon'],
		talon_db = config['talon']['talon_db'],
		talon_config = config['talon']['talon_config']
	output:
		talon_ra = config['talon']['talon_read_annot']
	threads: 16
	resources:
		mem_gb = 32
	conda: 
		'envs/talon.yaml'
	shell: 
		'talon \
    	--f {input.talon_config} \
    	--db {input.talon_db} \
    	--build {ref_fa_name} \
    	--tmpDir ./data/{exp}/{exp}_talon-tmp \
    	--threads {threads} \
    	--o ./data/{exp}/{exp} \
    	&& rm -r ./data/{exp}/{exp}_talon-tmp'
