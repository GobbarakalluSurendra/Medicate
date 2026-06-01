import io
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, HRFlowable
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle

def generate_prescription_pdf(prescription):
    """
    Generates a PDF bytes buffer containing a professional medical prescription.
    Expects prescription dictionary containing: hospital_name, hospital_address,
    doctor_name, doctor_specialization, doctor_phone, patient_id, patient_name,
    created_at, diagnosis, medicines, and instructions.
    """
    buffer = io.BytesIO()
    
    # 1. Page setup - Letter size with 40 pt margins
    doc = SimpleDocTemplate(
        buffer,
        pagesize=letter,
        rightMargin=40,
        leftMargin=40,
        topMargin=40,
        bottomMargin=40
    )
    
    styles = getSampleStyleSheet()
    
    # 2. Typography Styles
    title_style = ParagraphStyle(
        'DocHospitalTitle',
        parent=styles['Heading1'],
        fontName='Helvetica-Bold',
        fontSize=20,
        textColor=colors.HexColor('#004D40'),  # Deep Teal
        spaceAfter=4
    )
    
    section_title = ParagraphStyle(
        'DocSectionTitle',
        parent=styles['Heading2'],
        fontName='Helvetica-Bold',
        fontSize=12,
        textColor=colors.HexColor('#00796B'),  # Light Teal
        spaceBefore=12,
        spaceAfter=6
    )
    
    body_style = ParagraphStyle(
        'DocBodyStyle',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=10,
        leading=14,
        textColor=colors.HexColor('#212121')
    )
    
    body_bold_style = ParagraphStyle(
        'DocBodyBoldStyle',
        parent=body_style,
        fontName='Helvetica-Bold'
    )
    
    story = []
    
    # 3. Header Block (Branding & Hospital Info)
    story.append(Paragraph(prescription.get('hospital_name', 'TELEMEDICINE CLINIC').upper(), title_style))
    story.append(Paragraph(prescription.get('hospital_address', 'Clinical Center address not specified'), body_style))
    story.append(Spacer(1, 10))
    story.append(HRFlowable(width="100%", thickness=2, color=colors.HexColor('#004D40'), spaceBefore=5, spaceAfter=15))
    
    # 4. Doctor / Patient Metadata Table
    formatted_date = 'N/A'
    if prescription.get('created_at'):
        try:
            formatted_date = prescription.get('created_at').strftime('%Y-%m-%d')
        except AttributeError:
            formatted_date = str(prescription.get('created_at'))
            
    info_data = [
        [
            Paragraph(f"<b>Doctor:</b> {prescription.get('doctor_name', 'N/A')}", body_style),
            Paragraph(f"<b>Patient ID:</b> PAT-{prescription.get('patient_id', 'N/A')}", body_style)
        ],
        [
            Paragraph(f"<b>Specialization:</b> {prescription.get('doctor_specialization', 'N/A')}", body_style),
            Paragraph(f"<b>Patient Name:</b> {prescription.get('patient_name', 'N/A')}", body_style)
        ],
        [
            Paragraph(f"<b>Phone:</b> {prescription.get('doctor_phone', 'N/A')}", body_style),
            Paragraph(f"<b>Date:</b> {formatted_date}", body_style)
        ]
    ]
    
    info_table = Table(info_data, colWidths=[260, 260])
    info_table.setStyle(TableStyle([
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('BOTTOMPADDING', (0,0), (-1,-1), 5),
    ]))
    
    story.append(info_table)
    story.append(Spacer(1, 10))
    story.append(HRFlowable(width="100%", thickness=1, color=colors.HexColor('#B2DFDB'), spaceBefore=5, spaceAfter=15))
    
    # 5. Diagnosis Area
    story.append(Paragraph("DIAGNOSIS & CLINICAL OBSERVATIONS", section_title))
    story.append(Paragraph(prescription.get('diagnosis', 'No diagnosis documented.').replace('\n', '<br/>'), body_style))
    story.append(Spacer(1, 12))
    
    # 6. Rx Medicines Prescription Grid
    story.append(Paragraph("Rx (PRESCRIBED MEDICATIONS)", section_title))
    
    # Extract line-by-line items
    raw_meds = prescription.get('medicines', '')
    med_lines = [m.strip() for m in raw_meds.split('\n') if m.strip()]
    if not med_lines:
        med_lines = [m.strip() for m in raw_meds.split(',') if m.strip()]
        
    table_headers = [
        Paragraph("<b>Medication Name</b>", body_bold_style), 
        Paragraph("<b>Dosage & Instructions</b>", body_bold_style)
    ]
    meds_table_data = [table_headers]
    
    for med in med_lines:
        if ':' in med:
            parts = med.split(':', 1)
            meds_table_data.append([Paragraph(parts[0].strip(), body_style), Paragraph(parts[1].strip(), body_style)])
        elif '-' in med:
            parts = med.split('-', 1)
            meds_table_data.append([Paragraph(parts[0].strip(), body_style), Paragraph(parts[1].strip(), body_style)])
        else:
            meds_table_data.append([Paragraph(med, body_style), Paragraph("As directed by physician", body_style)])
            
    # Empty state handler
    if len(meds_table_data) == 1:
        meds_table_data.append([Paragraph("No medications specified.", body_style), Paragraph("-", body_style)])
        
    meds_table = Table(meds_table_data, colWidths=[220, 300])
    meds_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor('#E0F2F1')),
        ('ALIGN', (0,0), (-1,-1), 'LEFT'),
        ('BOTTOMPADDING', (0,0), (-1,-1), 6),
        ('TOPPADDING', (0,0), (-1,-1), 6),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor('#B2DFDB')),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
    ]))
    
    story.append(meds_table)
    story.append(Spacer(1, 12))
    
    # 7. Additional Advisory Guidelines
    instructions = prescription.get('instructions', '')
    if instructions:
        story.append(Paragraph("ADVISORY INSTRUCTIONS / LIFESTYLE GUIDANCE", section_title))
        story.append(Paragraph(instructions.replace('\n', '<br/>'), body_style))
        story.append(Spacer(1, 15))
        
    # 8. Signature Block
    story.append(Spacer(1, 30))
    sig_content = [
        ["", "______________________________"],
        ["", f"Dr. {prescription.get('doctor_name', 'N/A')}"],
        ["", f"Reg ID: {prescription.get('doctor_id', 'N/A')}"]
    ]
    sig_table = Table(sig_content, colWidths=[320, 200])
    sig_table.setStyle(TableStyle([
        ('ALIGN', (1,0), (1,-1), 'CENTER'),
        ('BOTTOMPADDING', (0,0), (-1,-1), 2),
    ]))
    story.append(sig_table)
    
    # Build PDF
    doc.build(story)
    buffer.seek(0)
    return buffer
