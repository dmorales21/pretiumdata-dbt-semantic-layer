# Anchor Loans Dynamic Agents Integration Plan

## Date: 2025-12-30
## Status: 🔄 **IN PROGRESS**

---

## Objective

Ensure **all Anchor Loans data flows through STRATA's Dynamic Agents framework**, enabling:
- Complete entity extraction (ASTRA)
- Proper classification (ATHENA)
- Pattern detection (METIS)
- Governance validation (THEMIS)
- Decision orchestration (HERMES)
- Process automation (ARGO)

---

## Current State Analysis

### ✅ Existing Anchor Loans Infrastructure

1. **Data Sources**:
   - `SOURCE_ENTITY.ANCHOR_LOANS.DEALS` - Deal pipeline data
   - `ANALYTICS_PROD.ANCHOR_LOANS.V_DEAL_SCREENING_DATA` - Screening intelligence
   - `ANALYTICS_PROD.FACTS.FACT_SIGNAL_VALUE` - Signal metrics (GC_CAPACITY, DELTA_V, VELOCITY)
   - Construction permit data (HUD, Census)
   - Market metrics (CBSA-level)

2. **API Routes**:
   - `/api/anchor/markets` - Market intelligence
   - `/api/deals/anchor` - Deal list
   - `/api/deals/anchor/map` - Deal map data
   - `/api/deals/anchor/<deal_id>` - Deal detail
   - `/api/deals/anchor/<deal_id>/screening` - Deal screening

3. **Context Configuration**:
   - Domain: `FINANCING`
   - Taxons: `FIN_VALUATION`, `FIN_LIQUIDITY`, `FIN_LENDING`
   - Geography: `CBSA`
   - Product Scope: `CONSTRUCTION`, `SF`, `MF`, `BTR`
   - Offering: `RED` (Residential Development)

### ⚠️ Gaps Identified

1. **ASTRA Integration**: Anchor-specific entity extraction not fully configured
2. **ATHENA Integration**: Deal classification not using Dynamic Agents
3. **METIS Integration**: Pattern detection not applied to Anchor deals
4. **THEMIS Integration**: Governance validation not enforced on Anchor data
5. **Knowledge Orchestration**: Anchor deals not creating knowledge objects
6. **Agent Chain Logging**: Anchor operations not logged to `AGENT_CHAIN_LOG`

---

## Integration Plan

### Phase 1: ASTRA (Data Navigator) Integration

#### 1.1 Anchor-Specific Entity Extraction

**Objective**: Ensure ASTRA extracts all Anchor-relevant entities from deals, markets, and construction data.

**Implementation**:

```python
# In strata_agent/knowledge_orchestrator.py - LingoAgent (ASTRA)

def extract_entities(self, content: str, opco_context: Optional[str] = None) -> Dict:
    """Extract entities with Anchor-specific rules"""
    entities = {
        'markets': [],
        'metrics': [],
        'products': [],
        'opcos': [],
        'key_phrases': [],
        'deals': [],  # NEW for Anchor
        'construction_entities': []  # NEW for Anchor
    }
    
    # Anchor-specific extraction
    if opco_context == 'ANCHOR' or 'anchor' in content.lower():
        # Extract deal entities
        if 'deal' in content.lower() or 'loan' in content.lower():
            entities['deals'].append(self._extract_deal_id(content))
            entities['products'].append('CONSTRUCTION')
        
        # Extract construction entities
        if any(kw in content.lower() for kw in ['permit', 'builder', 'construction', 'completion']):
            entities['construction_entities'].extend([
                'PERMIT_VELOCITY',
                'GC_CAPACITY',
                'BUILDER_CAPACITY',
                'CONSTRUCTION_PIPELINE'
            ])
        
        # Extract Anchor-specific metrics
        anchor_metrics = ['GC_CAPACITY', 'PERMIT_VELOCITY', 'DELTA_V', 'VELOCITY', 
                         'DSCR', 'LTV', 'CONSTRUCTION_STAGE', 'COMPLETION_DATE']
        for metric in anchor_metrics:
            if metric.lower() in content.lower():
                entities['metrics'].append(metric)
        
        # Extract CBSA entities (Anchor uses CBSA-level)
        if 'cbsa' in content.lower() or any(city in content.lower() for city in ['phoenix', 'atlanta', 'austin']):
            entities['markets'].extend(self._extract_cbsa_entities(content))
    
    return entities
```

**Data Sources to Integrate**:
- `SOURCE_ENTITY.ANCHOR_LOANS.DEALS` → Extract: DEAL_ID, DEAL_NAME, LOAN_AMOUNT, LOAN_TYPE, CBSA_CODE
- `ANALYTICS_PROD.ANCHOR_LOANS.V_DEAL_SCREENING_DATA` → Extract: Screening metrics, risk scores
- Construction permit data → Extract: PERMIT_COUNT, PERMIT_VALUE, BUILDER_NAME
- Market metrics → Extract: CBSA-level construction activity

**Configuration Updates**:
- Update `agent_config.json` with Anchor-specific ASTRA rules (✅ DONE)
- Add Anchor data sources to `context_mappings`

---

### Phase 2: ATHENA (Learning Scientist) Integration

#### 2.1 Anchor Deal Classification

**Objective**: Classify Anchor deals into appropriate taxons (FIN_LENDING, FIN_VALUATION, HOU_SUPPLY).

**Implementation**:

```python
# In strata_agent/knowledge_orchestrator.py - AthenaAgent

def classify(self, content: str, entities: Dict, opco_context: Optional[str] = None) -> Dict:
    """Classify with Anchor-specific rules"""
    classification = {
        'taxon': 'KNW_ANNOTATIONS',
        'domain': 'HOUSING',
        'tags': []
    }
    
    # Anchor-specific classification
    if opco_context == 'ANCHOR':
        # Determine domain based on content
        if any(kw in content.lower() for kw in ['loan', 'lending', 'underwriting', 'DSCR', 'LTV']):
            classification['domain'] = 'FINANCING'
            classification['taxon'] = 'FIN_LENDING'
            classification['tags'].extend(['anchor_deal', 'construction_lending', 'underwriting'])
        
        elif any(kw in content.lower() for kw in ['valuation', 'cap rate', 'yield', 'IRR']):
            classification['domain'] = 'FINANCING'
            classification['taxon'] = 'FIN_VALUATION'
            classification['tags'].extend(['anchor_deal', 'valuation', 'investment'])
        
        elif any(kw in content.lower() for kw in ['permit', 'construction', 'supply', 'pipeline']):
            classification['domain'] = 'HOUSING'
            classification['taxon'] = 'HOU_SUPPLY'
            classification['tags'].extend(['anchor_deal', 'construction', 'supply'])
        
        # Add Anchor-specific tags
        classification['tags'].append('opco:ANCHOR')
        classification['tags'].append('offering:RED')
        classification['tags'].append('product_type:CONSTRUCTION')
    
    return classification
```

**Integration Points**:
- `/api/deals/anchor` → Classify each deal
- `/api/deals/anchor/<deal_id>/screening` → Classify screening data
- Deal registration → Classify new deals

---

### Phase 3: METIS (Knowledge Philosopher) Integration

#### 3.1 Anchor Pattern Detection

**Objective**: Detect patterns in Anchor deals, construction markets, and underwriting decisions.

**Implementation**:

```python
# In strata_agent/knowledge_orchestrator.py - MetisAgent

def find_similar(self, knowledge_id: str, top_k: int = 5, opco_context: Optional[str] = None) -> List[Dict]:
    """Find similar knowledge with Anchor-specific patterns"""
    similar = []
    
    if opco_context == 'ANCHOR':
        # Find similar Anchor deals
        cursor = self.conn.cursor()
        cursor.execute("""
            SELECT 
                k.KNOWLEDGE_ID,
                k.CONTENT,
                k.TAXON,
                k.DOMAIN,
                SIMILARITY(k.EMBEDDING, (SELECT EMBEDDING FROM ADMIN.KNOWLEDGE.EMBEDDINGS WHERE ENTITY_ID = %s)) as similarity_score
            FROM ADMIN.KNOWLEDGE.KNOWLEDGE_OBJECTS k
            JOIN ADMIN.KNOWLEDGE.EMBEDDINGS e ON k.KNOWLEDGE_ID = e.ENTITY_ID
            WHERE k.OPCO_CONTEXT = 'ANCHOR'
              AND k.DOMAIN IN ('FINANCING', 'HOUSING')
              AND k.TAXON IN ('FIN_LENDING', 'FIN_VALUATION', 'HOU_SUPPLY')
            ORDER BY similarity_score DESC
            LIMIT %s
        """, (knowledge_id, top_k))
        
        for row in cursor.fetchall():
            similar.append({
                'knowledge_id': row[0],
                'content': row[1],
                'taxon': row[2],
                'domain': row[3],
                'similarity_score': float(row[4])
            })
    
    return similar

def detect_patterns(self, entities: Dict, opco_context: Optional[str] = None) -> List[Dict]:
    """Detect Anchor-specific patterns"""
    patterns = []
    
    if opco_context == 'ANCHOR':
        # Detect construction patterns
        if 'PERMIT_VELOCITY' in entities.get('metrics', []) and 'CONSTRUCTION_PIPELINE' in entities.get('metrics', []):
            patterns.append({
                'pattern_type': 'construction_velocity',
                'description': 'Permit velocity correlates with construction pipeline',
                'confidence': 0.85
            })
        
        # Detect underwriting patterns
        if 'DSCR' in entities.get('metrics', []) and 'LTV' in entities.get('metrics', []):
            patterns.append({
                'pattern_type': 'underwriting_metrics',
                'description': 'DSCR and LTV used together for underwriting',
                'confidence': 0.90
            })
    
    return patterns
```

**Pattern Detection Focus**:
- Construction delay patterns
- Absorption velocity patterns
- Builder concentration patterns
- Permit-to-completion patterns
- Underwriting decision patterns

---

### Phase 4: THEMIS (Governance Controller) Integration

#### 4.1 Anchor Data Governance Validation

**Objective**: Validate Anchor data quality, completeness, and compliance.

**Implementation**:

```python
# In strata_agent/knowledge_orchestrator.py - ThemisAgent

def validate_anchor_data(self, deal_id: Optional[str] = None, market_data: Optional[Dict] = None) -> Dict:
    """Validate Anchor-specific data governance"""
    validation = {
        'valid': True,
        'badge': 'GREEN',
        'issues': [],
        'quality_score': 1.0
    }
    
    # Validate deal data
    if deal_id:
        cursor = self.conn.cursor()
        cursor.execute("""
            SELECT 
                DEAL_ID,
                DEAL_NAME,
                LOAN_AMOUNT,
                LOAN_TYPE,
                CBSA_CODE,
                DECISION_STATUS,
                DATA_QUALITY_SCORE,
                LAST_UPDATED
            FROM SOURCE_ENTITY.ANCHOR_LOANS.DEALS
            WHERE DEAL_ID = %s
        """, (deal_id,))
        
        deal = cursor.fetchone()
        if not deal:
            validation['valid'] = False
            validation['badge'] = 'RED'
            validation['issues'].append('Deal not found')
        else:
            # Check required fields
            required_fields = ['DEAL_NAME', 'LOAN_AMOUNT', 'LOAN_TYPE', 'CBSA_CODE']
            for field in required_fields:
                if deal[field] is None:
                    validation['valid'] = False
                    validation['badge'] = 'AMBER'
                    validation['issues'].append(f'Missing required field: {field}')
            
            # Check data quality
            quality_score = deal[6] if deal[6] else 0.0
            if quality_score < 0.85:
                validation['valid'] = False
                validation['badge'] = 'AMBER' if quality_score >= 0.70 else 'RED'
                validation['issues'].append(f'Data quality score below threshold: {quality_score}')
            
            # Check freshness
            last_updated = deal[7]
            if last_updated:
                days_old = (datetime.now() - last_updated).days
                if days_old > 7:
                    validation['valid'] = False
                    validation['badge'] = 'AMBER'
                    validation['issues'].append(f'Data is {days_old} days old (max 7 days)')
    
    # Validate market data
    if market_data:
        # Check CBSA coverage
        if 'CBSA_CODE' not in market_data:
            validation['valid'] = False
            validation['badge'] = 'AMBER'
            validation['issues'].append('Missing CBSA_CODE in market data')
        
        # Check required construction metrics
        required_metrics = ['GC_CAPACITY', 'PERMIT_VELOCITY', 'DELTA_V']
        for metric in required_metrics:
            if metric not in market_data.get('metrics', []):
                validation['valid'] = False
                validation['badge'] = 'AMBER'
                validation['issues'].append(f'Missing required metric: {metric}')
    
    return validation
```

**Governance Rules**:
- Deal data quality ≥ 0.85
- Construction metrics freshness ≤ 14 days
- Permit data freshness ≤ 7 days
- CBSA-level coverage required
- All required fields present

---

### Phase 5: HERMES (Decisions Executive) Integration

#### 5.1 Anchor Deal Underwriting Workflow

**Objective**: Orchestrate Anchor deal underwriting decisions through Dynamic Agents.

**Implementation**:

```python
# New file: strata_agent/hermes_agent.py

class HermesAgent:
    """Decisions Executive - Decision orchestration and workflow management"""
    
    def __init__(self, snowflake_conn):
        self.conn = snowflake_conn
    
    def orchestrate_anchor_deal_underwriting(self, deal_id: str) -> Dict:
        """Orchestrate Anchor deal underwriting workflow"""
        workflow_steps = []
        
        # Step 1: ASTRA - Extract deal entities
        astra = LingoAgent()
        deal_content = self._get_deal_content(deal_id)
        entities = astra.extract_entities(deal_content, opco_context='ANCHOR')
        workflow_steps.append({
            'agent': 'ASTRA',
            'step': 'extract_deal_entities',
            'output': entities,
            'status': 'completed'
        })
        
        # Step 2: ASTRA - Extract market context
        market_entities = astra.extract_entities(
            self._get_market_content(entities.get('markets', [])),
            opco_context='ANCHOR'
        )
        workflow_steps.append({
            'agent': 'ASTRA',
            'step': 'extract_market_context',
            'output': market_entities,
            'status': 'completed'
        })
        
        # Step 3: ATHENA - Classify deal
        athena = AthenaAgent()
        classification = athena.classify(deal_content, entities, opco_context='ANCHOR')
        workflow_steps.append({
            'agent': 'ATHENA',
            'step': 'classify_deal_type',
            'output': classification,
            'status': 'completed'
        })
        
        # Step 4: METIS - Find similar deals
        metis = MetisAgent(self.conn)
        similar_deals = metis.find_similar(deal_id, top_k=5, opco_context='ANCHOR')
        workflow_steps.append({
            'agent': 'METIS',
            'step': 'find_similar_deals',
            'output': similar_deals,
            'status': 'completed'
        })
        
        # Step 5: HERMES - Calculate underwriting metrics
        underwriting_metrics = self._calculate_underwriting_metrics(deal_id, entities, market_entities)
        workflow_steps.append({
            'agent': 'HERMES',
            'step': 'calculate_underwriting_metrics',
            'output': underwriting_metrics,
            'status': 'completed'
        })
        
        # Step 6: ARGO - Validate underwriting rules
        argo = ArgoAgent(self.conn)
        rule_validation = argo.validate_underwriting_rules(deal_id, underwriting_metrics)
        workflow_steps.append({
            'agent': 'ARGO',
            'step': 'validate_underwriting_rules',
            'output': rule_validation,
            'status': 'completed'
        })
        
        # Step 7: THEMIS - Validate governance
        themis = ThemisAgent(self.conn)
        governance_validation = themis.validate_anchor_data(deal_id=deal_id, market_data=market_entities)
        workflow_steps.append({
            'agent': 'THEMIS',
            'step': 'validate_governance',
            'output': governance_validation,
            'status': 'completed'
        })
        
        # Generate decision
        decision = self._generate_underwriting_decision(workflow_steps)
        
        # Log to AGENT_CHAIN_LOG
        self._log_agent_chain('ANCHOR_DEALS', deal_id, workflow_steps, decision)
        
        return {
            'deal_id': deal_id,
            'workflow_steps': workflow_steps,
            'decision': decision,
            'governance_validation': governance_validation
        }
    
    def _calculate_underwriting_metrics(self, deal_id: str, entities: Dict, market_entities: Dict) -> Dict:
        """Calculate Anchor underwriting metrics"""
        cursor = self.conn.cursor()
        
        # Get deal data
        cursor.execute("""
            SELECT LOAN_AMOUNT, LOAN_TYPE, CBSA_CODE
            FROM SOURCE_ENTITY.ANCHOR_LOANS.DEALS
            WHERE DEAL_ID = %s
        """, (deal_id,))
        deal = cursor.fetchone()
        
        # Get market metrics
        cursor.execute("""
            SELECT 
                GC_CAPACITY,
                PERMIT_VELOCITY,
                DELTA_V,
                VELOCITY
            FROM ANALYTICS_PROD.FACTS.FACT_SIGNAL_VALUE
            WHERE GEOGRAPHY_ID = %s
              AND SIGNAL_ID IN ('GC_CAPACITY', 'PERMIT_VELOCITY', 'DELTA_V', 'VELOCITY')
              AND AS_OF_DATE = (SELECT MAX(AS_OF_DATE) FROM ANALYTICS_PROD.FACTS.FACT_SIGNAL_VALUE)
        """, (deal[2],))
        
        market_metrics = {row[0]: row[1] for row in cursor.fetchall()}
        
        # Calculate DSCR, LTV, etc. (placeholder - implement actual calculation logic)
        metrics = {
            'DSCR': self._calculate_dscr(deal, market_metrics),
            'LTV': self._calculate_ltv(deal, market_metrics),
            'construction_risk_score': self._calculate_construction_risk(market_metrics),
            'absorption_risk_score': self._calculate_absorption_risk(market_metrics)
        }
        
        cursor.close()
        return metrics
```

**Workflow Steps**:
1. ASTRA: Extract deal entities
2. ASTRA: Extract market context
3. ATHENA: Classify deal type
4. METIS: Find similar deals
5. HERMES: Calculate underwriting metrics
6. ARGO: Validate underwriting rules
7. THEMIS: Validate governance

---

### Phase 6: ARGO (Process Engineer) Integration

#### 6.1 Anchor Deal Registration Automation

**Objective**: Automate Anchor deal registration and enrichment processes.

**Implementation**:

```python
# New file: strata_agent/argo_agent.py

class ArgoAgent:
    """Process Engineer - Process automation and workflow orchestration"""
    
    def __init__(self, snowflake_conn):
        self.conn = snowflake_conn
    
    def automate_deal_registration(self, deal_data: Dict) -> Dict:
        """Automate Anchor deal registration process"""
        process_steps = []
        
        # Step 1: ASTRA - Extract deal data
        astra = LingoAgent()
        entities = astra.extract_entities(str(deal_data), opco_context='ANCHOR')
        process_steps.append({
            'step': 'extract_deal_data',
            'agent': 'ASTRA',
            'status': 'completed'
        })
        
        # Step 2: ATHENA - Classify deal
        athena = AthenaAgent()
        classification = athena.classify(str(deal_data), entities, opco_context='ANCHOR')
        process_steps.append({
            'step': 'classify_deal',
            'agent': 'ATHENA',
            'status': 'completed'
        })
        
        # Step 3: ARGO - Validate deal schema
        schema_validation = self._validate_deal_schema(deal_data)
        process_steps.append({
            'step': 'validate_deal_schema',
            'agent': 'ARGO',
            'status': 'completed' if schema_validation['valid'] else 'failed'
        })
        
        # Step 4: ARGO - Trigger market data enrichment
        if schema_validation['valid']:
            enrichment_result = self._trigger_market_enrichment(deal_data.get('CBSA_CODE'))
            process_steps.append({
                'step': 'trigger_market_data_enrichment',
                'agent': 'ARGO',
                'status': 'completed' if enrichment_result['success'] else 'failed'
            })
        
        # Step 5: METIS - Find similar deals
        metis = MetisAgent(self.conn)
        similar_deals = metis.find_similar(deal_data.get('DEAL_ID'), top_k=3, opco_context='ANCHOR')
        process_steps.append({
            'step': 'find_similar_deals',
            'agent': 'METIS',
            'status': 'completed'
        })
        
        # Step 6: THEMIS - Validate governance
        themis = ThemisAgent(self.conn)
        governance_validation = themis.validate_anchor_data(deal_id=deal_data.get('DEAL_ID'))
        process_steps.append({
            'step': 'validate_governance',
            'agent': 'THEMIS',
            'status': 'completed' if governance_validation['valid'] else 'failed'
        })
        
        return {
            'deal_id': deal_data.get('DEAL_ID'),
            'process_steps': process_steps,
            'schema_validation': schema_validation,
            'governance_validation': governance_validation,
            'similar_deals': similar_deals
        }
```

**Automation Triggers**:
- New deal registered → Trigger market data enrichment
- Deal status changed → Trigger workflow update
- Market data updated → Trigger deal re-evaluation

---

### Phase 7: Knowledge Orchestration Integration

#### 7.1 Anchor Deal Knowledge Creation

**Objective**: Create knowledge objects for Anchor deals, enabling institutional memory.

**Implementation**:

```python
# In anchor_strata_routes.py - Integrate knowledge orchestration

from strata_agent.knowledge_orchestrator import KnowledgeOrchestrator

# Initialize orchestrator
orchestrator = KnowledgeOrchestrator(snowflake_conn, enable_collaboration=True)

@app.route('/api/deals/anchor/register', methods=['POST'])
def register_anchor_deal():
    """Register new Anchor deal and create knowledge object"""
    deal_data = request.json
    
    # ... existing deal registration logic ...
    
    # Create knowledge object
    knowledge_result = orchestrator.create_knowledge_with_collaboration(
        source_type='anchor_deal_registration',
        content=f"Anchor deal registered: {deal_data.get('DEAL_NAME')} - Loan Amount: {deal_data.get('LOAN_AMOUNT')}",
        user_id=request.headers.get('X-User-ID', 'system'),
        query=f"Should we underwrite deal {deal_data.get('DEAL_ID')}?",
        opco_context='ANCHOR'
    )
    
    # Link knowledge to deal
    cursor.execute("""
        UPDATE SOURCE_ENTITY.ANCHOR_LOANS.DEALS
        SET KNOWLEDGE_ID = %s
        WHERE DEAL_ID = %s
    """, (knowledge_result['knowledge_id'], deal_data.get('DEAL_ID')))
    
    return jsonify({
        'deal_id': deal_data.get('DEAL_ID'),
        'knowledge_id': knowledge_result['knowledge_id'],
        'collaboration_result': knowledge_result.get('collaboration_result')
    })
```

**Knowledge Creation Points**:
- Deal registration → Create knowledge object
- Deal status change → Update knowledge object
- Underwriting decision → Create decision knowledge
- Market analysis → Create market knowledge

---

### Phase 8: Agent Chain Logging

#### 8.1 Log Anchor Operations to AGENT_CHAIN_LOG

**Objective**: Log all Anchor operations to enable Explain Chain visualization.

**Implementation**:

```sql
-- Create AGENT_CHAIN_LOG table if not exists
CREATE TABLE IF NOT EXISTS ADMIN.GOVERNANCE.AGENT_CHAIN_LOG (
    CHAIN_ID VARCHAR PRIMARY KEY,
    CONTEXT_ID VARCHAR,
    MODULE VARCHAR,
    CHAIN_TYPE VARCHAR,  -- 'ANCHOR_MARKETS', 'ANCHOR_DEALS', 'ANCHOR_SCREENING'
    AGENT_NAME VARCHAR,
    STEP_NUMBER INT,
    INPUT_SIGNATURE VARCHAR,
    OUTPUT_SIGNATURE VARCHAR,
    QUALITY_SCORE FLOAT,
    EXECUTION_TIME_MS INT,
    STATUS VARCHAR,  -- 'completed', 'failed', 'pending'
    ERROR_MESSAGE VARCHAR,
    CREATED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    FOREIGN KEY (CONTEXT_ID) REFERENCES ADMIN.GOVERNANCE.USER_CONTEXT(CONTEXT_ID)
);
```

**Logging Points**:
- `/api/anchor/markets` → Log ASTRA → ATHENA → METIS → THEMIS chain
- `/api/deals/anchor` → Log ASTRA → HERMES → ARGO → THEMIS chain
- `/api/deals/anchor/<deal_id>/screening` → Log ASTRA → METIS → HERMES → THEMIS chain

---

## Implementation Checklist

### ✅ Configuration
- [x] Create `agent_config.json` with Anchor-specific rules
- [x] Update `OPCO_CONTEXT_MAP` with Anchor configuration
- [ ] Update `AGENT_DOMAIN_MAP` with Anchor agent bundles

### 🔄 Code Integration
- [ ] Enhance `LingoAgent.extract_entities()` with Anchor-specific extraction
- [ ] Enhance `AthenaAgent.classify()` with Anchor-specific classification
- [ ] Enhance `MetisAgent.find_similar()` with Anchor-specific patterns
- [ ] Enhance `ThemisAgent.validate()` with Anchor-specific governance
- [ ] Create `HermesAgent` class for decision orchestration
- [ ] Create `ArgoAgent` class for process automation

### 🔄 Route Integration
- [ ] Integrate knowledge orchestration into `/api/deals/anchor/register`
- [ ] Integrate agent chain logging into all Anchor routes
- [ ] Add "Explain Chain" button to Anchor deal pages
- [ ] Create `/api/ledger/chain/anchor/<deal_id>` endpoint

### 🔄 Database Integration
- [ ] Create `AGENT_CHAIN_LOG` table
- [ ] Create `ANCHOR_DEAL_KNOWLEDGE` view linking deals to knowledge
- [ ] Create `ANCHOR_MARKET_INTELLIGENCE` view aggregating agent outputs

### 🔄 Testing
- [ ] Test ASTRA entity extraction for Anchor deals
- [ ] Test ATHENA classification for Anchor deals
- [ ] Test METIS pattern detection for Anchor deals
- [ ] Test THEMIS governance validation for Anchor data
- [ ] Test HERMES underwriting workflow
- [ ] Test ARGO deal registration automation
- [ ] Test knowledge creation for Anchor deals
- [ ] Test Explain Chain visualization for Anchor operations

---

## Success Criteria

1. **ASTRA**: All Anchor deals, markets, and construction data extracted with proper entities
2. **ATHENA**: All Anchor content classified into FIN_LENDING, FIN_VALUATION, HOU_SUPPLY taxons
3. **METIS**: Anchor patterns detected (construction delays, absorption velocity, builder concentration)
4. **THEMIS**: All Anchor data validated with governance badges (GREEN/AMBER/RED)
5. **HERMES**: Anchor deal underwriting workflows orchestrated through agent chains
6. **ARGO**: Anchor deal registration automated with agent collaboration
7. **Knowledge**: All Anchor operations create knowledge objects for institutional memory
8. **Explain Chain**: All Anchor operations visible in Explain Chain panel

---

## Next Steps

1. **Implement Phase 1-2** (ASTRA + ATHENA integration) - Priority 1
2. **Implement Phase 3-4** (METIS + THEMIS integration) - Priority 2
3. **Implement Phase 5-6** (HERMES + ARGO integration) - Priority 3
4. **Implement Phase 7-8** (Knowledge + Logging) - Priority 4
5. **Test end-to-end** - Priority 5
6. **Deploy to production** - Priority 6

---

## Related Documentation

- `docs/STRATA_DYNAMIC_AGENTS_ENHANCEMENT_QUESTIONS.md` - Enhancement questions
- `strata_agent/dynamic_chains.md` - Dynamic agent chains specification
- `config/dynamic_agents/agent_config.json` - Agent configuration
- `anchor_strata_routes.py` - Anchor routes implementation

