import os
import datetime
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak, Table, TableStyle, Image
from reportlab.lib import colors
from reportlab.lib.units import inch
from reportlab.platypus.flowables import KeepTogether

class PDFGenerator:
    def __init__(self, output_dir="output"):
        self.output_dir = output_dir
        if not os.path.exists(self.output_dir):
            os.makedirs(self.output_dir)

    def generate_strategy_pdf(self, calendar_data: dict) -> str:
        filename = f"{self.output_dir}/strategy_{calendar_data.get('id', 'plan')}.pdf"
        
        # Build Document
        doc = SimpleDocTemplate(
            filename, 
            pagesize=letter,
            rightMargin=inch, 
            leftMargin=inch, 
            topMargin=inch, 
            bottomMargin=inch
        )
        
        styles = getSampleStyleSheet()
        
        # Define Premium Brand Colors
        brand_primary = colors.HexColor("#6366F1")
        brand_dark = colors.HexColor("#0B0D17")
        brand_muted = colors.HexColor("#64748B")
        brand_bg = colors.HexColor("#F8FAFC")
        
        # Custom Typography Styles
        title_style = ParagraphStyle(
            'TitleStyle',
            parent=styles['Title'],
            fontName='Helvetica-Bold',
            fontSize=28,
            textColor=brand_dark,
            spaceAfter=24,
            alignment=1 # Center
        )
        
        subtitle_style = ParagraphStyle(
            'SubtitleStyle',
            parent=styles['Normal'],
            fontName='Helvetica',
            fontSize=14,
            textColor=brand_muted,
            spaceAfter=40,
            alignment=1 # Center
        )
        
        h1_style = ParagraphStyle(
            'H1',
            parent=styles['Heading1'],
            fontName='Helvetica-Bold',
            fontSize=20,
            textColor=brand_primary,
            spaceBefore=20,
            spaceAfter=12
        )
        
        h2_style = ParagraphStyle(
            'H2',
            parent=styles['Heading2'],
            fontName='Helvetica-Bold',
            fontSize=16,
            textColor=brand_dark,
            spaceBefore=15,
            spaceAfter=10
        )
        
        h3_style = ParagraphStyle(
            'H3',
            parent=styles['Heading3'],
            fontName='Helvetica-Bold',
            fontSize=13,
            textColor=brand_primary,
            spaceBefore=10,
            spaceAfter=6
        )
        
        body_style = ParagraphStyle(
            'Body',
            parent=styles['Normal'],
            fontName='Helvetica',
            fontSize=11,
            textColor=colors.HexColor("#334155"),
            leading=16,
            spaceAfter=10
        )
        
        elements = []
        
        # ==========================================
        # 1. Cover Page
        # ==========================================
        elements.append(Spacer(1, 120))
        elements.append(Paragraph("AI CREATOR COPILOT", subtitle_style))
        elements.append(Paragraph("Monthly Content Strategy Deck", title_style))
        elements.append(Spacer(1, 40))
        
        # Executive Summary Box
        exec_data = [
            ['Niche', calendar_data.get('niche', '')],
            ['Target Audience', calendar_data.get('audience', '')],
            ['Primary Goal', calendar_data.get('goal', '')],
            ['Frequency', calendar_data.get('frequency', '')],
            ['Generated On', datetime.datetime.now().strftime("%Y-%m-%d")]
        ]
        
        exec_table = Table(exec_data, colWidths=[2*inch, 4*inch])
        exec_table.setStyle(TableStyle([
            ('BACKGROUND', (0,0), (-1,-1), brand_bg),
            ('TEXTCOLOR', (0,0), (0,-1), brand_muted),
            ('TEXTCOLOR', (1,0), (1,-1), brand_dark),
            ('FONTNAME', (0,0), (0,-1), 'Helvetica-Bold'),
            ('FONTNAME', (1,0), (1,-1), 'Helvetica'),
            ('FONTSIZE', (0,0), (-1,-1), 11),
            ('BOTTOMPADDING', (0,0), (-1,-1), 12),
            ('TOPPADDING', (0,0), (-1,-1), 12),
            ('GRID', (0,0), (-1,-1), 1, colors.white),
            ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ]))
        
        elements.append(exec_table)
        elements.append(PageBreak())
        
        # ==========================================
        # 2. Executive Strategy & Gap Analysis
        # ==========================================
        elements.append(Paragraph("Executive Strategy", h1_style))
        elements.append(Paragraph(f"<b>Monthly Goal:</b> {calendar_data.get('monthlyGoal', '')}", body_style))
        
        kpis = calendar_data.get('monthlyKPIs', [])
        if kpis:
            elements.append(Paragraph("<b>Key Performance Indicators (KPIs):</b>", h3_style))
            for kpi in kpis:
                elements.append(Paragraph(f"• {kpi}", body_style))
                
        elements.append(Spacer(1, 15))
        
        gap_analysis = calendar_data.get("contentGapAnalysis", {})
        if gap_analysis:
            elements.append(Paragraph("Content Gap Analysis", h2_style))
            
            gap_data = [
                ['Missing in Niche', gap_analysis.get('missingInNiche', '')],
                ['Competitor Weakness', gap_analysis.get('competitorWeakness', '')],
                ['Our Opportunity', gap_analysis.get('opportunity', '')],
            ]
            gap_table = Table(gap_data, colWidths=[2*inch, 4.5*inch])
            gap_table.setStyle(TableStyle([
                ('BACKGROUND', (0,0), (0,-1), brand_primary),
                ('TEXTCOLOR', (0,0), (0,-1), colors.white),
                ('BACKGROUND', (1,0), (1,-1), brand_bg),
                ('TEXTCOLOR', (1,0), (1,-1), brand_dark),
                ('FONTNAME', (0,0), (0,-1), 'Helvetica-Bold'),
                ('FONTNAME', (1,0), (1,-1), 'Helvetica'),
                ('FONTSIZE', (0,0), (-1,-1), 10),
                ('BOTTOMPADDING', (0,0), (-1,-1), 10),
                ('TOPPADDING', (0,0), (-1,-1), 10),
                ('GRID', (0,0), (-1,-1), 1, colors.white),
                ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
            ]))
            elements.append(gap_table)
            
        elements.append(PageBreak())
        
        # ==========================================
        # 3. Weekly Roadmaps
        # ==========================================
        elements.append(Paragraph("Weekly Roadmaps", h1_style))
        
        for week in calendar_data.get("weeks", []):
            elements.append(Paragraph(f"Week {week.get('weekNumber', '')} Strategy", h2_style))
            elements.append(Paragraph(f"<b>Objective:</b> {week.get('weeklyGoal', '')}", body_style))
            elements.append(Paragraph(f"<b>Strategy:</b> {week.get('weeklyStrategy', '')}", body_style))
            
            coach = week.get("growthCoach", {})
            if coach:
                elements.append(Spacer(1, 5))
                coach_data = [
                    ['Growth Coach: Improve', coach.get('improve', '')],
                    ['Growth Coach: Stop', coach.get('stop', '')],
                ]
                coach_table = Table(coach_data, colWidths=[2*inch, 4.5*inch])
                coach_table.setStyle(TableStyle([
                    ('BACKGROUND', (0,0), (0,0), colors.HexColor("#22C55E")), # Green
                    ('BACKGROUND', (0,1), (0,1), colors.HexColor("#EF4444")), # Red
                    ('TEXTCOLOR', (0,0), (0,-1), colors.white),
                    ('BACKGROUND', (1,0), (1,-1), brand_bg),
                    ('TEXTCOLOR', (1,0), (1,-1), brand_dark),
                    ('FONTNAME', (0,0), (0,-1), 'Helvetica-Bold'),
                    ('FONTNAME', (1,0), (1,-1), 'Helvetica'),
                    ('FONTSIZE', (0,0), (-1,-1), 9),
                    ('BOTTOMPADDING', (0,0), (-1,-1), 8),
                    ('TOPPADDING', (0,0), (-1,-1), 8),
                    ('GRID', (0,0), (-1,-1), 1, colors.white),
                    ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
                ]))
                elements.append(coach_table)
            elements.append(Spacer(1, 20))
            
        elements.append(PageBreak())
        
        # ==========================================
        # 4. Daily Execution Plans
        # ==========================================
        elements.append(Paragraph("Daily Execution Plans", h1_style))
        
        for day in calendar_data.get("days", []):
            day_elements = []
            day_elements.append(Paragraph(f"Day {day.get('day', '')}: {day.get('title', '')}", h2_style))
            
            # Formulate detailed table
            data = [
                ['Hook', day.get('hook', '')],
                ['Script', day.get('fullScript', day.get('idea', ''))],
                ['Caption', day.get('caption', '')],
                ['CTA & Hashtags', f"{day.get('cta', '')}\n\n{day.get('hashtags', '')}"],
                ['Psychology', f"{day.get('psychologyUsed', '')} - {day.get('whyThisWorks', '')}"],
                ['Visuals', f"Format: {day.get('contentFormat', '')}\nB-Roll: {day.get('bRollSuggestions', '')}"]
            ]
            
            t = Table(data, colWidths=[1.2*inch, 5.3*inch])
            t.setStyle(TableStyle([
                ('BACKGROUND', (0,0), (0,-1), brand_primary),
                ('TEXTCOLOR', (0,0), (0,-1), colors.white),
                ('BACKGROUND', (1,0), (1,-1), brand_bg),
                ('TEXTCOLOR', (1,0), (1,-1), brand_dark),
                ('FONTNAME', (0,0), (0,-1), 'Helvetica-Bold'),
                ('FONTNAME', (1,0), (1,-1), 'Helvetica'),
                ('FONTSIZE', (0,0), (-1,-1), 10),
                ('BOTTOMPADDING', (0,0), (-1,-1), 8),
                ('TOPPADDING', (0,0), (-1,-1), 8),
                ('GRID', (0,0), (-1,-1), 1, colors.white),
                ('VALIGN', (0,0), (-1,-1), 'TOP'),
            ]))
            
            day_elements.append(t)
            day_elements.append(Spacer(1, 25))
            
            # Keep day content together so it doesn't break across pages awkwardly
            elements.append(KeepTogether(day_elements))
            
        # Build PDF
        doc.build(elements)
        return filename
