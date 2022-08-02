import pandas as pd

# read sample file and get sample names
metadata = pd.read_csv('samples.csv', sep=',')
metadata_df = pd.DataFrame(data = metadata)
sn_list = metadata_df['sample_file_name'].tolist()

# set reference names:
ref_fa_name = config['reference']['mouse']['fa_name'],
ref_gtf_name = config['reference']['mouse']['gtf_name']

rule all:
	input:
		expand( config['sample']['labeled'], samplename=sn_list)

rule install_transcriptclean:
	output:
		directory('packages/TranscriptClean')
	conda: 
		'envs/transcriptclean.yaml'
	resources:
		mem_gb = 16
	shell: 
		'git clone https://github.com/mortazavilab/TranscriptClean.git ./packages/TranscriptClean'

rule install_talon:
	output:
		directory('packages/TALON')
	conda: 
		'envs/talon.yaml'
	resources:
		mem_gb = 16
	shell:
		'git clone --branch development https://github.com/mortazavilab/TALON.git ./packages/TALON && pip3 install ./packages/TALON'

rule minimap:
	input: 
		fastq = config['fastq'],
		ref_fa = config['reference']['mouse']['fa'],
		ref_bed = config['reference']['mouse']['bed']
	output: 
		sam = temp(config['sample']['sam'])
	threads: 16
	resources:
		mem_gb = 64
	log: "data/mapped/logs/minimap_{samplename}.log"
	shell:
		'minimap2 --MD -t {threads} -ax splice:hq -uf --junc-bed {input.ref_bed} \
		{input.ref_fa} {input.fastq} > {output.sam} 2> {log}'

rule sam_to_bam:
	input: 
		sam = config['sample']['sam']
	output:
		bam = temp(config['sample']['bam'])
	threads: 4
	resources:
		mem_gb = 16
	shell:
		'samtools sort --threads={threads} -O bam {input.sam} > {output.bam}'

rule bam_reversed:
    input:
        bam = config['sample']['bam']
    output:
        bam_reversed = temp(config['sample']['bam_reversed'])
    threads: 4
    resources:
        mem_gb = 16
    script:
        "scripts/reversed_bam.py"

rule sorted_sam:
	input:
		bam = config['sample']['bam_reversed']
	output:
		sorted_sam = config['sample']['sorted']
	threads: 4
	resources:
		mem_gb = 16
	shell:
		'samtools view -h --threads={threads} {input.bam} > {output.sorted_sam}'

rule transcriptclean:
	input:
		sorted_sam = config['sample']['sorted'],
		tc = config['packages']['transcriptclean'],
		ref_fa = config['reference']['mouse']['fa'],
		ref_sj = config['reference']['mouse']['sj']
	output:
		clean = config['sample']['clean'] 
	threads: 16
	resources:
		mem_gb = 32
	conda: 
		'envs/transcriptclean.yaml'
	shell: 
		'mkdir ./data/processed/{wildcards.samplename}_tc-tmp && \
		python {input.tc}/TranscriptClean.py \
		-t {threads} \
		--sam {input.sorted_sam} \
		--genome {input.ref_fa} \
		--spliceJns {input.ref_sj} \
		--canonOnly \
		--primaryOnly \
		--deleteTmp \
		--outprefix ./data/processed/{wildcards.samplename}_tc-tmp/{wildcards.samplename} && \
		mv ./data/processed/{wildcards.samplename}_tc-tmp/{wildcards.samplename}* ./data/processed/ \
		&& rm -r ./data/processed/{wildcards.samplename}_tc-tmp'

rule talon_label_reads:
	input:
		talon = config['packages']['talon'],
		clean = config['sample']['clean'],
		ref_fa = config['reference']['mouse']['fa']
	output:
		labeled = config['sample']['labeled']
	threads: 16
	resources:
		mem_gb = 32
	conda: 
		'envs/talon.yaml'
	shell: 
		'talon_label_reads \
    	--f {input.clean} \
    	--g {input.ref_fa} \
    	--t {threads} \
		--tmpDir ./data/processed/{wildcards.samplename}_talon-tmp \
		--ar 20  \
		--deleteTmp \
    	--o ./data/processed/{wildcards.samplename}'
    	