-- ============================================================================
-- REF: Epoch AI Capability Taxonomy
-- Purpose: Canonical AI capability dimensions mapping raw Epoch AI task names
--   to standardized capability groups for the AI automation/replacement risk model.
-- Source: Manual curation (CTE). Optional future: SOURCE_PROD.EPOCH_AI.AI_MODEL_TASKS.
-- Feeds: ref_epoch_to_gwa_crosswalk; cleaned_onet_soc_ai_exposure (capability coverage).
-- ============================================================================

{{ config(
    alias='REF_EPOCH_CAPABILITY_TAXONOMY',
    materialized='table',
    tags=['transform', 'transform_dev', 'epoch_ai', 'pretium_epoch', 'T-ANALYTICS-LABOR-AUTOMATION-RISK-STACK'],
) }}

WITH taxonomy AS (
    -- LANGUAGE GENERATION
    SELECT 'LANGUAGE_GENERATION'   AS capability_dimension, 'Language modeling/generation' AS epoch_task_name, TRUE AS is_labor_market_relevant
    UNION ALL SELECT 'LANGUAGE_GENERATION', 'Language modeling', TRUE
    UNION ALL SELECT 'LANGUAGE_GENERATION', 'Language generation', TRUE
    UNION ALL SELECT 'LANGUAGE_GENERATION', 'Text autocompletion', TRUE
    UNION ALL SELECT 'LANGUAGE_GENERATION', 'Chat', TRUE
    UNION ALL SELECT 'LANGUAGE_GENERATION', 'Vision-language generation', TRUE

    -- INFORMATION EXTRACTION
    UNION ALL SELECT 'INFORMATION_EXTRACTION', 'Question answering', TRUE
    UNION ALL SELECT 'INFORMATION_EXTRACTION', 'Named entity recognition (NER)', TRUE
    UNION ALL SELECT 'INFORMATION_EXTRACTION', 'Relation extraction', TRUE
    UNION ALL SELECT 'INFORMATION_EXTRACTION', 'Character recognition (OCR)', TRUE
    UNION ALL SELECT 'INFORMATION_EXTRACTION', 'Search', TRUE
    UNION ALL SELECT 'INFORMATION_EXTRACTION', 'Retrieval-augmented generation', TRUE
    UNION ALL SELECT 'INFORMATION_EXTRACTION', 'Sentiment classification', TRUE
    UNION ALL SELECT 'INFORMATION_EXTRACTION', 'Document classification', TRUE
    UNION ALL SELECT 'INFORMATION_EXTRACTION', 'Part-of-speech tagging', TRUE
    UNION ALL SELECT 'INFORMATION_EXTRACTION', 'Semantic search', TRUE
    UNION ALL SELECT 'INFORMATION_EXTRACTION', 'Table tasks', TRUE
    UNION ALL SELECT 'INFORMATION_EXTRACTION', 'Transcription', TRUE

    -- SUMMARIZATION & SYNTHESIS
    UNION ALL SELECT 'SUMMARIZATION_SYNTHESIS', 'Text summarization', TRUE
    UNION ALL SELECT 'SUMMARIZATION_SYNTHESIS', 'Translation', TRUE
    UNION ALL SELECT 'SUMMARIZATION_SYNTHESIS', 'Document representation', TRUE

    -- QUANTITATIVE REASONING
    UNION ALL SELECT 'QUANTITATIVE_REASONING', 'Quantitative reasoning', TRUE
    UNION ALL SELECT 'QUANTITATIVE_REASONING', 'Mathematical reasoning', TRUE
    UNION ALL SELECT 'QUANTITATIVE_REASONING', 'Mathematical simulation', TRUE
    UNION ALL SELECT 'QUANTITATIVE_REASONING', 'Reasoning', TRUE
    UNION ALL SELECT 'QUANTITATIVE_REASONING', 'Numerical simulation', TRUE
    UNION ALL SELECT 'QUANTITATIVE_REASONING', 'Automated theorem proving', TRUE
    UNION ALL SELECT 'QUANTITATIVE_REASONING', 'Theorem proving', TRUE
    UNION ALL SELECT 'QUANTITATIVE_REASONING', 'Financial management', TRUE

    -- CODE GENERATION
    UNION ALL SELECT 'CODE_GENERATION', 'Code generation', TRUE
    UNION ALL SELECT 'CODE_GENERATION', 'Code autocompletion', TRUE
    UNION ALL SELECT 'CODE_GENERATION', 'Coding', TRUE

    -- VISUAL ANALYSIS
    UNION ALL SELECT 'VISUAL_ANALYSIS', 'Image classification', TRUE
    UNION ALL SELECT 'VISUAL_ANALYSIS', 'Image captioning', TRUE
    UNION ALL SELECT 'VISUAL_ANALYSIS', 'Visual question answering', TRUE
    UNION ALL SELECT 'VISUAL_ANALYSIS', 'Object detection', TRUE
    UNION ALL SELECT 'VISUAL_ANALYSIS', 'Object recognition', TRUE
    UNION ALL SELECT 'VISUAL_ANALYSIS', 'Face detection', TRUE
    UNION ALL SELECT 'VISUAL_ANALYSIS', 'Face recognition', TRUE
    UNION ALL SELECT 'VISUAL_ANALYSIS', 'Face verification', TRUE
    UNION ALL SELECT 'VISUAL_ANALYSIS', 'Semantic segmentation', TRUE
    UNION ALL SELECT 'VISUAL_ANALYSIS', 'Image segmentation', TRUE
    UNION ALL SELECT 'VISUAL_ANALYSIS', 'Medical diagnosis', TRUE
    UNION ALL SELECT 'VISUAL_ANALYSIS', 'Cancer diagnosis', TRUE
    UNION ALL SELECT 'VISUAL_ANALYSIS', 'Pattern recognition', TRUE
    UNION ALL SELECT 'VISUAL_ANALYSIS', 'Pattern classification', TRUE
    UNION ALL SELECT 'VISUAL_ANALYSIS', 'Binary classification', TRUE
    UNION ALL SELECT 'VISUAL_ANALYSIS', 'Digit recognition', TRUE
    UNION ALL SELECT 'VISUAL_ANALYSIS', '(Visual) Question answering', TRUE

    -- AUDIO & SPEECH
    UNION ALL SELECT 'AUDIO_SPEECH', 'Speech recognition (ASR)', TRUE
    UNION ALL SELECT 'AUDIO_SPEECH', 'Speech synthesis', TRUE
    UNION ALL SELECT 'AUDIO_SPEECH', 'Speech-to-text', TRUE
    UNION ALL SELECT 'AUDIO_SPEECH', 'Text-to-speech (TTS)', TRUE
    UNION ALL SELECT 'AUDIO_SPEECH', 'Speech completion', TRUE
    UNION ALL SELECT 'AUDIO_SPEECH', 'Speech-to-speech', TRUE
    UNION ALL SELECT 'AUDIO_SPEECH', 'Audio classification', TRUE
    UNION ALL SELECT 'AUDIO_SPEECH', 'Audio question answering', TRUE
    UNION ALL SELECT 'AUDIO_SPEECH', 'Voice identification', TRUE

    -- PLANNING & AGENTIC
    UNION ALL SELECT 'PLANNING_AGENTIC', 'System control', TRUE
    UNION ALL SELECT 'PLANNING_AGENTIC', 'Instruction following', TRUE
    UNION ALL SELECT 'PLANNING_AGENTIC', 'Instruction interpretation', TRUE
    UNION ALL SELECT 'PLANNING_AGENTIC', 'Function calling', TRUE

    -- DOMAIN SPECIFIC (narrow professional impact)
    UNION ALL SELECT 'DOMAIN_SPECIFIC', 'Drug discovery', TRUE
    UNION ALL SELECT 'DOMAIN_SPECIFIC', 'Weather forecasting', TRUE

    -- NON_WORK_RELEVANT (exclude from labor model)
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'Atari', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'Go', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'Chess', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'Backgammon', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'Poker', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'Checkers', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'Shogi', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'Stratego', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'Diplomacy', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'Hanabi', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'Dota 2', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'StarCraft', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'Robotic manipulation', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'Self-driving car', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'Helicopter driving', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'Protein folding prediction', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'Protein generation', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'Protein or nucleotide language model (pLM/nLM)', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'Protein representation learning', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'Protein classification', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'Protein design', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'Protein embedding', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'Protein function prediction', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'Protein interaction prediction', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'Protein inverse folding', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'Protein pathogenicity prediction', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'Protein property prediction', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'Protein-ligand binding affinity prediction', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'Protein-ligand contact prediction', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'Protein contact and distance prediction', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'Protein localization prediction', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'Antibody property prediction', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'Nucleotide generation', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'RNA structure prediction', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'RNA-Protein interaction prediction', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'Enzyme function prediction', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'Crystal discovery', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', '3D reconstruction', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', '3D segmentation', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'Maze solving', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'Route finding', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'Pole balancing', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'Open ended play', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'Animal (human/non-human) imitation', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'Sports', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'Tic Tac Toe', FALSE
    UNION ALL SELECT 'NON_WORK_RELEVANT', 'Capture the flag', FALSE
)

SELECT
    capability_dimension,
    epoch_task_name,
    is_labor_market_relevant,
    CURRENT_TIMESTAMP() AS created_at,
    'v1_pilot' AS taxonomy_version
FROM taxonomy
