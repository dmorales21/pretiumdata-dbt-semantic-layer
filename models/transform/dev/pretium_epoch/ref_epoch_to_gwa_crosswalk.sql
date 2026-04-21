-- TRANSFORM.DEV.REF_EPOCH_TO_GWA_CROSSWALK — Pretium curated Epoch capability → O*NET GWA weights.
-- Vendor/dataset: pretium / epoch_refs (manual curation). Port: pretium-ai-dbt `ref_epoch_to_gwa_crosswalk.sql`.
{{ config(
    alias='REF_EPOCH_TO_GWA_CROSSWALK',
    materialized='table',
    tags=['transform', 'transform_dev', 'epoch_ai', 'pretium_epoch', 'T-ANALYTICS-LABOR-AUTOMATION-RISK-STACK'],
) }}

WITH crosswalk AS (
    SELECT 'LANGUAGE_GENERATION' AS capability_dimension, '4.A.3.b.6' AS gwa_activity_id, 'Documenting/Recording Information' AS gwa_activity_name, 0.90 AS exposure_weight, TRUE AS is_augmentation_primary, 'HIGH' AS confidence_level, 'LLMs draft, structure, and transcribe documents at near-human quality' AS mapping_rationale
    UNION ALL SELECT 'LANGUAGE_GENERATION', '4.A.4.a.1', 'Interpreting the Meaning of Information for Others', 0.75, TRUE, 'HIGH', 'Language models explain, summarize, and translate complex content for audiences'
    UNION ALL SELECT 'LANGUAGE_GENERATION', '4.A.4.b.3', 'Training and Teaching Others', 0.55, TRUE, 'MEDIUM', 'AI can generate instructional content and personalized explanations'
    UNION ALL SELECT 'LANGUAGE_GENERATION', '4.A.4.a.2', 'Communicating with Supervisors, Peers, or Subordinates', 0.50, TRUE, 'MEDIUM', 'AI drafts internal communications; human relationship context limits substitution'
    UNION ALL SELECT 'LANGUAGE_GENERATION', '4.A.4.a.3', 'Communicating with People Outside the Organization', 0.55, TRUE, 'MEDIUM', 'AI drafts external correspondence; brand/relationship context partially limits'
    UNION ALL SELECT 'INFORMATION_EXTRACTION', '4.A.2.a.2', 'Processing Information', 0.90, FALSE, 'HIGH', 'Parsing, classifying, and routing information is a core LLM/NLP capability'
    UNION ALL SELECT 'INFORMATION_EXTRACTION', '4.A.1.a.1', 'Getting Information', 0.85, TRUE, 'HIGH', 'AI retrieves and surfaces relevant information from large corpora'
    UNION ALL SELECT 'INFORMATION_EXTRACTION', '4.A.2.a.3', 'Evaluating Information to Determine Compliance with Standards', 0.70, FALSE, 'HIGH', 'Rule-based compliance checking is a primary use case for NLP extraction'
    UNION ALL SELECT 'INFORMATION_EXTRACTION', '4.A.1.b.1', 'Identifying Objects, Actions, and Events', 0.65, TRUE, 'MEDIUM', 'OCR + NER extracts entities and events from documents and images'
    UNION ALL SELECT 'SUMMARIZATION_SYNTHESIS', '4.A.2.a.4', 'Analyzing Data or Information', 0.85, TRUE, 'HIGH', 'Synthesis of large document sets into structured findings is a core LLM strength'
    UNION ALL SELECT 'SUMMARIZATION_SYNTHESIS', '4.A.2.a.2', 'Processing Information', 0.75, TRUE, 'HIGH', 'Summarization reduces document sets into structured findings'
    UNION ALL SELECT 'SUMMARIZATION_SYNTHESIS', '4.A.4.a.1', 'Interpreting the Meaning of Information for Others', 0.70, TRUE, 'HIGH', 'Translation and executive summaries are direct summarization outputs'
    UNION ALL SELECT 'QUANTITATIVE_REASONING', '4.A.2.a.4', 'Analyzing Data or Information', 0.90, FALSE, 'HIGH', 'Mathematical and quantitative analysis is core model capability post-2022'
    UNION ALL SELECT 'QUANTITATIVE_REASONING', '4.A.2.b.1', 'Making Decisions and Solving Problems', 0.70, FALSE, 'MEDIUM', 'Structured problem-solving and scenario analysis increasingly automated; judgment remains human'
    UNION ALL SELECT 'QUANTITATIVE_REASONING', '4.A.1.b.3', 'Estimating the Quantifiable Characteristics of Products, Events, or Information', 0.80, FALSE, 'HIGH', 'Estimation, forecasting, and quantification are strong reasoning model outputs'
    UNION ALL SELECT 'QUANTITATIVE_REASONING', '4.A.2.a.3', 'Evaluating Information to Determine Compliance with Standards', 0.65, FALSE, 'MEDIUM', 'Quantitative standards checking (financial compliance, QA) increasingly automated'
    UNION ALL SELECT 'CODE_GENERATION', '4.A.3.b.1', 'Working with Computers', 0.85, TRUE, 'HIGH', 'Code generation directly accelerates all computer-mediated work activities'
    UNION ALL SELECT 'CODE_GENERATION', '4.A.3.b.2', 'Drafting, Laying Out, and Specifying Technical Devices, Parts, and Equipment', 0.65, FALSE, 'MEDIUM', 'Automated spec generation applies to software architecture and some technical design'
    UNION ALL SELECT 'CODE_GENERATION', '4.A.2.b.1', 'Making Decisions and Solving Problems', 0.55, TRUE, 'MEDIUM', 'AI-assisted debugging and architecture decisions augment developer problem-solving'
    UNION ALL SELECT 'CODE_GENERATION', '4.A.3.b.6', 'Documenting/Recording Information', 0.70, TRUE, 'HIGH', 'Auto-generated code documentation and technical specifications'
    UNION ALL SELECT 'VISUAL_ANALYSIS', '4.A.1.b.1', 'Identifying Objects, Actions, and Events', 0.85, FALSE, 'HIGH', 'Computer vision identifies objects, defects, and anomalies in images and video'
    UNION ALL SELECT 'VISUAL_ANALYSIS', '4.A.1.b.2', 'Inspecting Equipment, Structures, or Materials', 0.70, FALSE, 'MEDIUM', 'Visual inspection AI applies to quality control, radiology, structural review; physical access still needed'
    UNION ALL SELECT 'VISUAL_ANALYSIS', '4.A.2.a.3', 'Evaluating Information to Determine Compliance with Standards', 0.65, FALSE, 'MEDIUM', 'Image-based compliance checking in manufacturing, construction, medical imaging'
    UNION ALL SELECT 'VISUAL_ANALYSIS', '4.A.2.a.4', 'Analyzing Data or Information', 0.60, FALSE, 'MEDIUM', 'Visual data analysis (charts, imagery, satellite) increasingly AI-assisted'
    UNION ALL SELECT 'AUDIO_SPEECH', '4.A.3.b.6', 'Documenting/Recording Information', 0.85, TRUE, 'HIGH', 'ASR transcription automates meeting notes, call logs, medical dictation'
    UNION ALL SELECT 'AUDIO_SPEECH', '4.A.1.a.1', 'Getting Information', 0.65, TRUE, 'HIGH', 'Voice interfaces and speech-to-text retrieve and capture information'
    UNION ALL SELECT 'AUDIO_SPEECH', '4.A.4.a.2', 'Communicating with Supervisors, Peers, or Subordinates', 0.45, TRUE, 'MEDIUM', 'AI voice agents handle routine internal communications; human judgment retained for complex'
    UNION ALL SELECT 'AUDIO_SPEECH', '4.A.4.a.3', 'Communicating with People Outside the Organization', 0.50, FALSE, 'MEDIUM', 'Customer service voice AI substitutes for call center agents in routine interactions'
    UNION ALL SELECT 'PLANNING_AGENTIC', '4.A.2.b.6', 'Organizing, Planning, and Prioritizing Work', 0.65, FALSE, 'MEDIUM', 'Agentic AI orchestrates multi-step workflows; human oversight still standard'
    UNION ALL SELECT 'PLANNING_AGENTIC', '4.A.2.b.5', 'Scheduling Work and Activities', 0.70, FALSE, 'HIGH', 'Scheduling and resource allocation automation is mature and widely deployed'
    UNION ALL SELECT 'PLANNING_AGENTIC', '4.A.2.b.4', 'Developing Objectives and Strategies', 0.45, FALSE, 'LOW', 'Strategic planning requires contextual judgment AI does not yet reliably provide'
    UNION ALL SELECT 'PLANNING_AGENTIC', '4.A.4.c.1', 'Performing Administrative Activities', 0.75, FALSE, 'HIGH', 'Administrative task orchestration is a primary agentic AI deployment target'
    UNION ALL SELECT 'PLANNING_AGENTIC', '4.A.2.b.3', 'Updating and Using Relevant Knowledge', 0.60, TRUE, 'MEDIUM', 'RAG and knowledge retrieval systems automate currency of knowledge for decisions'
)

SELECT
    capability_dimension,
    gwa_activity_id,
    gwa_activity_name,
    exposure_weight,
    is_augmentation_primary,
    confidence_level,
    mapping_rationale,
    CURRENT_TIMESTAMP() AS created_at,
    'v1_pilot' AS crosswalk_version
FROM crosswalk
