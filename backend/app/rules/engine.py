"""
Project PARAKH — Compliance Rule Engine

Orchestrator per §19/§20 that executes Legal Metrology rules (The Legal Metrology
(Packaged Commodities) Rules, 2011) against structured OCR & NLP extractions.
Aggregates verdicts and compiles statutory violation references.

Overall statuses: COMPLIANT, VIOLATION, REQUIRES_REVIEW, INSUFFICIENT_DATA, SERVICE_UNAVAILABLE.
"""

from __future__ import annotations

import json
import logging
from pathlib import Path
from typing import Any, Dict, List, Optional

from app.ai.nlp_extractor import ExtractedEntity
from app.rules.base import RuleResult
from app.rules.consumer_care_rule import ConsumerCareRule
from app.rules.date_rule import DateRule
from app.rules.font_size_rule import FontSizeRule
from app.rules.manufacturer_rule import ManufacturerRule
from app.rules.mrp_rule import MRPRule
from app.rules.net_quantity_rule import NetQuantityRule
from app.rules.openfoodfacts_rule import OpenFoodFactsRule, GS1Rule

logger = logging.getLogger("parakh.rules.engine")


class ComplianceEngine:
    """
    Central compliance rule engine orchestrator.

    Executes structured Legal Metrology rules against extracted entities and
    Open Food Facts catalog data to determine overall compliance.
    """

    def __init__(self, rules_json_path: Optional[str] = None):
        self.rules = [
            MRPRule(),
            NetQuantityRule(),
            DateRule(),
            ConsumerCareRule(),
            ManufacturerRule(),
            FontSizeRule(),
            OpenFoodFactsRule(),
        ]
        
        # Load declarative Legal Metrology statutory rules metadata
        self.rules_metadata: Dict[str, Dict[str, Any]] = {}
        self._load_rules_json(rules_json_path)

    def _load_rules_json(self, path: Optional[str] = None) -> None:
        """Load statutory rules definitions from JSON."""
        if path:
            json_file = Path(path)
        else:
            json_file = Path(__file__).parent / "legal_metrology_rules.json"

        if json_file.exists():
            try:
                with open(json_file, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    for r in data.get("rules", []):
                        self.rules_metadata[r.get("rule_id", "")] = r
                logger.info("Loaded %d statutory rules from %s", len(self.rules_metadata), json_file.name)
            except Exception as e:
                logger.warning("Failed to parse %s: %s", json_file, e)

    def evaluate(
        self,
        entities: List[ExtractedEntity],
        gs1_data: Optional[Dict[str, Any]] = None,
        ocr_text: str = "",
    ) -> Dict[str, Any]:
        """
        Evaluate all Legal Metrology compliance rules against extracted entities.

        Args:
            entities: Extracted NLP entities.
            gs1_data: Open Food Facts lookup result (if available).
            ocr_text: Raw OCR text for context.

        Returns:
            Dict containing overall_status, detailed rule_results, statutory citations,
            and legal notice draft clauses.
        """
        entity_map = {e.entity_type: e for e in entities}
        results: List[RuleResult] = []
        review_reasons: List[str] = []
        statutory_violations: List[Dict[str, Any]] = []

        # 1. Execute Core Evaluators
        for rule in self.rules:
            try:
                if isinstance(rule, (OpenFoodFactsRule, GS1Rule)):
                    result = rule.evaluate(entity_map, gs1_data)
                else:
                    result = rule.evaluate(entity_map)

                # Enrich with statutory metadata from JSON registry
                self._enrich_rule_result(result)
                results.append(result)

                if result.status == "REVIEW":
                    review_reasons.append(
                        f"{result.rule_name}: {result.explanation}"
                    )
                elif result.status == "FAIL":
                    statutory_violations.append({
                        "rule_id": result.rule_id,
                        "rule_number": result.rule_number or getattr(rule, "RULE_ID", "LM"),
                        "rule_name": result.rule_name,
                        "clause_id": result.clause_id,
                        "act_section": result.act_section or "Section 36(1) of Legal Metrology Act, 2009",
                        "severity": result.severity or "HIGH",
                        "explanation": result.explanation,
                        "notice_clause": result.default_notice_clause,
                    })

            except Exception as exc:
                logger.error("Rule %s failed: %s", rule.__class__.__name__, exc)
                results.append(RuleResult(
                    rule_id=getattr(rule, "RULE_ID", "unknown"),
                    rule_name=getattr(rule, "RULE_NAME", "Unknown Rule"),
                    status="NOT_AVAILABLE",
                    explanation=f"Rule evaluation error: {str(exc)}",
                ))

        # 2. Evaluate Additional Declarative JSON Clauses
        self._evaluate_declarative_clauses(entity_map, ocr_text, results, review_reasons, statutory_violations)

        # 3. Determine Overall Verdict
        overall_status = self._determine_overall_status(results)
        requires_review = overall_status in ("REQUIRES_REVIEW", "INSUFFICIENT_DATA")

        logger.info(
            "Compliance evaluation: %s (%d rules evaluated, %d pass, %d fail, %d review)",
            overall_status,
            len(results),
            sum(1 for r in results if r.status == "PASS"),
            sum(1 for r in results if r.status == "FAIL"),
            sum(1 for r in results if r.status == "REVIEW"),
        )

        return {
            "overall_status": overall_status,
            "rule_results": [r.to_dict() for r in results],
            "requires_human_review": requires_review,
            "review_reasons": review_reasons,
            "statutory_violations": statutory_violations,
            "total_rules_evaluated": len(results),
        }

    def _enrich_rule_result(self, result: RuleResult) -> None:
        """Enrich a RuleResult with statutory metadata from legal_metrology_rules.json."""
        # Map class rule_id to JSON rule_id
        meta_id = result.rule_id
        meta = self.rules_metadata.get(meta_id)
        
        if not meta:
            # Fallback by rule number matching
            for m in self.rules_metadata.values():
                if m.get("rule_title", "").lower() in result.rule_name.lower() or result.rule_name.lower() in m.get("rule_title", "").lower():
                    meta = m
                    break

        if meta:
            result.clause_id = meta.get("clause_id")
            result.rule_number = meta.get("rule_number")
            result.severity = meta.get("severity")
            legal = meta.get("legal_consequences", {})
            result.act_section = legal.get("act_section")
            result.default_notice_clause = legal.get("default_notice_clause")

    def _evaluate_declarative_clauses(
        self,
        entity_map: Dict[str, ExtractedEntity],
        ocr_text: str,
        results: List[RuleResult],
        review_reasons: List[str],
        statutory_violations: List[Dict[str, Any]],
    ) -> None:
        """Evaluate secondary declarative rules from JSON if not already evaluated."""
        existing_ids = {r.rule_id for r in results}

        # Rule 6(1)(aa): Country of Origin (if imported product)
        if "LM-007" in self.rules_metadata and "LM-007" not in existing_ids:
            meta = self.rules_metadata["LM-007"]
            is_imported = any(k in ocr_text.lower() for k in ["imported by", "made in", "product of", "country of origin"])
            coo_entity = entity_map.get("COUNTRY_OF_ORIGIN")
            
            if is_imported:
                if coo_entity and coo_entity.value:
                    res = RuleResult(
                        rule_id="LM-007",
                        rule_name=meta.get("rule_title", "Country of Origin"),
                        status="PASS",
                        extracted_value=coo_entity.value,
                        explanation=f"Country of origin declared as '{coo_entity.value}'",
                        clause_id=meta.get("clause_id"),
                        rule_number=meta.get("rule_number"),
                        severity=meta.get("severity"),
                        act_section=meta.get("legal_consequences", {}).get("act_section"),
                        default_notice_clause=meta.get("legal_consequences", {}).get("default_notice_clause"),
                    )
                else:
                    res = RuleResult(
                        rule_id="LM-007",
                        rule_name=meta.get("rule_title", "Country of Origin"),
                        status="FAIL",
                        extracted_value="Missing",
                        explanation="Imported product detected but Country of Origin declaration is missing",
                        clause_id=meta.get("clause_id"),
                        rule_number=meta.get("rule_number"),
                        severity=meta.get("severity"),
                        act_section=meta.get("legal_consequences", {}).get("act_section"),
                        default_notice_clause=meta.get("legal_consequences", {}).get("default_notice_clause"),
                    )
                    statutory_violations.append({
                        "rule_id": res.rule_id,
                        "rule_number": res.rule_number,
                        "rule_name": res.rule_name,
                        "clause_id": res.clause_id,
                        "act_section": res.act_section,
                        "severity": res.severity,
                        "explanation": res.explanation,
                        "notice_clause": res.default_notice_clause,
                    })
                results.append(res)

    def _determine_overall_status(self, results: List[RuleResult]) -> str:
        """
        Determine overall compliance status from individual rule results.

        Logic per §20:
        - Any FAIL → VIOLATION
        - All PASS → COMPLIANT
        - Any REVIEW (no FAIL) → REQUIRES_REVIEW
        - All NOT_AVAILABLE → INSUFFICIENT_DATA
        - Never compliant merely because data was unavailable
        """
        statuses = [r.status for r in results]

        if not statuses:
            return "INSUFFICIENT_DATA"

        has_fail = "FAIL" in statuses
        has_pass = "PASS" in statuses
        has_review = "REVIEW" in statuses
        has_unavailable = "NOT_AVAILABLE" in statuses

        if all(s == "NOT_AVAILABLE" for s in statuses):
            return "INSUFFICIENT_DATA"

        if has_fail:
            return "VIOLATION"

        if has_review:
            return "REQUIRES_REVIEW"

        if has_unavailable and has_pass:
            return "REQUIRES_REVIEW"

        if all(s == "PASS" for s in statuses):
            return "COMPLIANT"

        return "REQUIRES_REVIEW"
