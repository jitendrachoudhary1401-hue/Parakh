"""Initial schema — all 7 PostgreSQL tables

Revision ID: 001_initial
Revises: None
Create Date: 2026-08-26

Creates: users, inspections, gs1_products, citizen_reports,
         evidence, legal_notices, audit_logs.
No seed data — database starts empty per §5.
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID, JSONB


revision: str = "001_initial"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # --- users ---
    op.create_table(
        "users",
        sa.Column("user_id", UUID(as_uuid=True), primary_key=True),
        sa.Column("full_name", sa.String(255), nullable=False),
        sa.Column("email", sa.String(255), unique=True, nullable=False),
        sa.Column("hashed_password", sa.Text, nullable=False),
        sa.Column("role", sa.String(20), nullable=False, server_default="citizen"),
        sa.Column("zone_id", sa.String(50), nullable=True),
        sa.Column("phone", sa.String(20), nullable=True),
        sa.Column("is_active", sa.Boolean, nullable=False, server_default="true"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("last_login_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index("ix_users_email", "users", ["email"])
    op.create_index("ix_users_role", "users", ["role"])

    # --- gs1_products ---
    op.create_table(
        "gs1_products",
        sa.Column("barcode", sa.String(50), primary_key=True),
        sa.Column("registered_manufacturer", sa.String(500), nullable=True),
        sa.Column("manufacturer_address", sa.Text, nullable=True),
        sa.Column("product_name", sa.String(500), nullable=True),
        sa.Column("product_category", sa.String(255), nullable=True),
        sa.Column("brand", sa.String(255), nullable=True),
        sa.Column("metadata_json", JSONB, nullable=True),
        sa.Column("data_source", sa.String(50), nullable=False, server_default="gs1_api"),
        sa.Column("last_verified_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_gs1_products_category", "gs1_products", ["product_category"])

    # --- inspections ---
    op.create_table(
        "inspections",
        sa.Column("inspection_id", UUID(as_uuid=True), primary_key=True),
        sa.Column("inspector_id", UUID(as_uuid=True), sa.ForeignKey("users.user_id", ondelete="RESTRICT"), nullable=False),
        sa.Column("product_barcode", sa.String(50), nullable=True),
        sa.Column("latitude", sa.Float, nullable=True),
        sa.Column("longitude", sa.Float, nullable=True),
        sa.Column("location_name", sa.String(500), nullable=True),
        sa.Column("status", sa.String(30), nullable=False, server_default="pending"),
        sa.Column("overall_result", sa.String(30), nullable=True),
        sa.Column("image_storage_path", sa.Text, nullable=True),
        sa.Column("processed_image_path", sa.Text, nullable=True),
        sa.Column("blockchain_hash", sa.String(128), nullable=True),
        sa.Column("blockchain_tx_id", sa.String(256), nullable=True),
        sa.Column("notes", sa.Text, nullable=True),
        sa.Column("metadata_json", JSONB, nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_inspections_inspector_id", "inspections", ["inspector_id"])
    op.create_index("ix_inspections_status", "inspections", ["status"])
    op.create_index("ix_inspections_product_barcode", "inspections", ["product_barcode"])
    op.create_index("ix_inspections_created_at", "inspections", ["created_at"])

    # --- citizen_reports ---
    op.create_table(
        "citizen_reports",
        sa.Column("report_id", UUID(as_uuid=True), primary_key=True),
        sa.Column("citizen_id", UUID(as_uuid=True), sa.ForeignKey("users.user_id", ondelete="RESTRICT"), nullable=False),
        sa.Column("image_storage_path", sa.Text, nullable=True),
        sa.Column("description", sa.Text, nullable=True),
        sa.Column("product_barcode", sa.String(50), nullable=True),
        sa.Column("latitude", sa.Float, nullable=True),
        sa.Column("longitude", sa.Float, nullable=True),
        sa.Column("location_name", sa.String(500), nullable=True),
        sa.Column("ai_triage_status", sa.String(30), nullable=False, server_default="pending"),
        sa.Column("ai_triage_confidence", sa.Float, nullable=True),
        sa.Column("ai_triage_details", JSONB, nullable=True),
        sa.Column("admin_decision", sa.String(20), nullable=False, server_default="pending"),
        sa.Column("admin_notes", sa.Text, nullable=True),
        sa.Column("reviewed_by", UUID(as_uuid=True), sa.ForeignKey("users.user_id", ondelete="SET NULL"), nullable=True),
        sa.Column("source", sa.String(20), nullable=False, server_default="app"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("reviewed_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index("ix_citizen_reports_citizen_id", "citizen_reports", ["citizen_id"])
    op.create_index("ix_citizen_reports_ai_triage", "citizen_reports", ["ai_triage_status"])
    op.create_index("ix_citizen_reports_admin_decision", "citizen_reports", ["admin_decision"])
    op.create_index("ix_citizen_reports_created_at", "citizen_reports", ["created_at"])

    # --- evidence ---
    op.create_table(
        "evidence",
        sa.Column("evidence_id", UUID(as_uuid=True), primary_key=True),
        sa.Column("inspection_id", UUID(as_uuid=True), sa.ForeignKey("inspections.inspection_id", ondelete="RESTRICT"), nullable=False),
        sa.Column("inspector_id", UUID(as_uuid=True), sa.ForeignKey("users.user_id", ondelete="RESTRICT"), nullable=False),
        sa.Column("payload_hash", sa.String(128), nullable=False),
        sa.Column("image_storage_path", sa.Text, nullable=True),
        sa.Column("gps_latitude", sa.Float, nullable=True),
        sa.Column("gps_longitude", sa.Float, nullable=True),
        sa.Column("capture_timestamp", sa.DateTime(timezone=True), nullable=True),
        sa.Column("ocr_text_snapshot", sa.Text, nullable=True),
        sa.Column("violation_data", JSONB, nullable=True),
        sa.Column("blockchain_status", sa.String(20), nullable=False, server_default="pending"),
        sa.Column("blockchain_tx_id", sa.String(256), nullable=True),
        sa.Column("blockchain_receipt", JSONB, nullable=True),
        sa.Column("verification_status", sa.String(20), nullable=False, server_default="unverified"),
        sa.Column("last_verified_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_evidence_inspection_id", "evidence", ["inspection_id"])
    op.create_index("ix_evidence_payload_hash", "evidence", ["payload_hash"])
    op.create_index("ix_evidence_blockchain_status", "evidence", ["blockchain_status"])

    # --- legal_notices ---
    op.create_table(
        "legal_notices",
        sa.Column("notice_id", UUID(as_uuid=True), primary_key=True),
        sa.Column("inspection_id", UUID(as_uuid=True), sa.ForeignKey("inspections.inspection_id", ondelete="RESTRICT"), nullable=False),
        sa.Column("generated_by", UUID(as_uuid=True), sa.ForeignKey("users.user_id", ondelete="RESTRICT"), nullable=False),
        sa.Column("pdf_storage_path", sa.Text, nullable=True),
        sa.Column("product_info", JSONB, nullable=True),
        sa.Column("violations", JSONB, nullable=True),
        sa.Column("compliance_results", JSONB, nullable=True),
        sa.Column("evidence_references", JSONB, nullable=True),
        sa.Column("inspector_name", sa.String(255), nullable=True),
        sa.Column("inspection_location", sa.Text, nullable=True),
        sa.Column("blockchain_receipt", sa.String(256), nullable=True),
        sa.Column("status", sa.String(20), nullable=False, server_default="draft"),
        sa.Column("generated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("served_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index("ix_legal_notices_inspection_id", "legal_notices", ["inspection_id"])
    op.create_index("ix_legal_notices_status", "legal_notices", ["status"])

    # --- audit_logs ---
    op.create_table(
        "audit_logs",
        sa.Column("log_id", UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", UUID(as_uuid=True), nullable=True),
        sa.Column("user_email", sa.String(255), nullable=True),
        sa.Column("user_role", sa.String(20), nullable=True),
        sa.Column("action", sa.String(100), nullable=False),
        sa.Column("resource_type", sa.String(50), nullable=True),
        sa.Column("resource_id", sa.String(100), nullable=True),
        sa.Column("details", JSONB, nullable=True),
        sa.Column("ip_address", sa.String(45), nullable=True),
        sa.Column("user_agent", sa.Text, nullable=True),
        sa.Column("request_method", sa.String(10), nullable=True),
        sa.Column("request_path", sa.String(500), nullable=True),
        sa.Column("status", sa.String(20), nullable=False, server_default="success"),
        sa.Column("timestamp", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_audit_logs_user_id", "audit_logs", ["user_id"])
    op.create_index("ix_audit_logs_action", "audit_logs", ["action"])
    op.create_index("ix_audit_logs_resource_type", "audit_logs", ["resource_type"])
    op.create_index("ix_audit_logs_timestamp", "audit_logs", ["timestamp"])


def downgrade() -> None:
    op.drop_table("audit_logs")
    op.drop_table("legal_notices")
    op.drop_table("evidence")
    op.drop_table("citizen_reports")
    op.drop_table("inspections")
    op.drop_table("gs1_products")
    op.drop_table("users")
