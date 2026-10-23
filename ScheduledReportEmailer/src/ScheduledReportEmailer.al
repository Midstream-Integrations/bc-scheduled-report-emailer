table 50190 "MID Scheduled Report"
{
    Caption = 'Scheduled Report';
    DataClassification = CustomerContent;
    LookupPageId = "MID Scheduled Reports";
    DrillDownPageId = "MID Scheduled Reports";

    fields
    {
        field(1; "Code"; Code[20]) { Caption = 'Code'; NotBlank = true; }
        field(2; Description; Text[100]) { Caption = 'Description'; }
        field(3; "Report ID"; Integer)
        {
            Caption = 'Report ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Report));
            trigger OnValidate()
            begin
                if "Report ID" <> xRec."Report ID" then
                    Clear("Request Parameters");
            end;
        }
        field(4; "Report Caption"; Text[250])
        {
            Caption = 'Report Name';
            FieldClass = FlowField;
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Report), "Object ID" = field("Report ID")));
            Editable = false;
        }
        field(5; Recipients; Text[250])
        {
            Caption = 'Recipients';
            ExtendedDatatype = EMail;
        }
        field(6; Subject; Text[250]) { Caption = 'Email Subject'; }
        field(7; Body; Text[2048]) { Caption = 'Email Body'; }
        field(8; "File Name Prefix"; Text[50]) { Caption = 'File Name Prefix'; }
        field(9; "Request Parameters"; Blob) { Caption = 'Saved Report Options'; }
        field(10; "Has Saved Options"; Boolean) { Caption = 'Has Saved Options'; Editable = false; }
        field(11; "Last Sent At"; DateTime) { Caption = 'Last Sent At'; Editable = false; DataClassification = SystemMetadata; }
        field(12; "Last Result"; Text[250]) { Caption = 'Last Result'; Editable = false; DataClassification = SystemMetadata; }
        field(13; "Output Format"; Option) { Caption = 'Output Format'; OptionMembers = PDF,Excel,Word; OptionCaption = 'PDF,Excel,Word'; }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }

    procedure GetRequestParameters() Params: Text
    var
        InStr: InStream;
    begin
        CalcFields("Request Parameters");
        if not "Request Parameters".HasValue() then
            exit('');
        "Request Parameters".CreateInStream(InStr, TextEncoding::UTF8);
        InStr.Read(Params);
    end;

    procedure SetRequestParameters(Params: Text)
    var
        OutStr: OutStream;
    begin
        Clear("Request Parameters");
        if Params <> '' then begin
            "Request Parameters".CreateOutStream(OutStr, TextEncoding::UTF8);
            OutStr.Write(Params);
        end;
        "Has Saved Options" := Params <> '';
    end;
}

page 50190 "MID Scheduled Reports"
{
    Caption = 'Scheduled Report Emails';
    PageType = List;
    SourceTable = "MID Scheduled Report";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Code"; Rec."Code") { ToolTip = 'Unique code. It is also the Parameter String of the Job Queue Entry that sends this report.'; }
                field(Description; Rec.Description) { ToolTip = 'What this schedule is for.'; }
                field("Report ID"; Rec."Report ID") { ToolTip = 'The report to run.'; }
                field("Report Caption"; Rec."Report Caption") { ToolTip = 'Name of the report.'; }
                field(Recipients; Rec.Recipients) { ToolTip = 'Email addresses, separated by semicolons.'; }
                field(Subject; Rec.Subject) { ToolTip = 'Email subject. %1 is replaced with today''s date.'; }
                field(Body; Rec.Body) { ToolTip = 'Email body (HTML allowed).'; }
                field("Output Format"; Rec."Output Format") { ToolTip = 'Attach the report as PDF, Excel or Word. Excel and Word need a report layout that supports them.'; }
                field("File Name Prefix"; Rec."File Name Prefix") { ToolTip = 'The file is named <prefix>_<yyyymmdd> plus the format''s extension.'; }
                field("Has Saved Options"; Rec."Has Saved Options") { ToolTip = 'Whether report options and filters have been saved with Set Report Options.'; }
                field("Last Sent At"; Rec."Last Sent At") { ToolTip = 'When the report was last emailed.'; }
                field("Last Result"; Rec."Last Result") { ToolTip = 'Result of the last send.'; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SetOptions)
            {
                Caption = 'Set Report Options';
                Image = SetupList;
                ToolTip = 'Open the report''s request page and save its options and filters with this entry.';
                trigger OnAction()
                var
                    Params: Text;
                begin
                    Rec.TestField("Report ID");
                    Params := Report.RunRequestPage(Rec."Report ID", Rec.GetRequestParameters());
                    if Params = '' then
                        exit; // cancelled
                    Rec.SetRequestParameters(Params);
                    Rec.Modify(true);
                end;
            }
            action(SendNow)
            {
                Caption = 'Send Now';
                Image = SendMail;
                ToolTip = 'Run the report and email it now.';
                trigger OnAction()
                var
                    Sender: Codeunit "MID Send Scheduled Report";
                begin
                    Sender.Send(Rec.Code);
                    Message('Sent %1 to %2.', Rec."Report Caption", Rec.Recipients);
                end;
            }
            action(CreateJob)
            {
                Caption = 'Create Job Queue Entry';
                Image = Job;
                ToolTip = 'Create an on-hold Job Queue Entry for this report. Set the schedule on the card, then set it to Ready.';
                trigger OnAction()
                var
                    JobQueueEntry: Record "Job Queue Entry";
                begin
                    JobQueueEntry.Init();
                    JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
                    JobQueueEntry."Object ID to Run" := Codeunit::"MID Send Scheduled Report";
                    JobQueueEntry."Parameter String" := Rec.Code;
                    JobQueueEntry.Description := CopyStr('Email report: ' + Rec.Description, 1, MaxStrLen(JobQueueEntry.Description));
                    JobQueueEntry."Recurring Job" := true;
                    JobQueueEntry.Status := JobQueueEntry.Status::"On Hold";
                    JobQueueEntry.Insert(true);
                    Page.Run(Page::"Job Queue Entry Card", JobQueueEntry);
                end;
            }
        }
        area(Promoted)
        {
            actionref(SetOptions_Promoted; SetOptions) { }
            actionref(SendNow_Promoted; SendNow) { }
            actionref(CreateJob_Promoted; CreateJob) { }
        }
    }
}

/// <summary>
/// Job Queue handler: Object Type Codeunit, ID 50191, Parameter String = the Scheduled Report code.
/// </summary>
codeunit 50191 "MID Send Scheduled Report"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        Send(CopyStr(Rec."Parameter String", 1, 20));
    end;

    procedure Send(EntryCode: Code[20])
    var
        Entry: Record "MID Scheduled Report";
        TempBlob: Codeunit "Temp Blob";
        EmailMessage: Codeunit "Email Message";
        Email: Codeunit Email;
        OutStr: OutStream;
        InStr: InStream;
        FileName: Text;
        Prefix: Text;
        NoEntryErr: Label 'Scheduled Report %1 does not exist. Check the Parameter String on the Job Queue Entry.', Comment = '%1 = code';
        SendFailedErr: Label 'The email could not be sent: %1', Comment = '%1 = error';
    begin
        if not Entry.Get(EntryCode) then
            Error(NoEntryErr, EntryCode);
        Entry.TestField("Report ID");
        Entry.TestField(Recipients);

        TempBlob.CreateOutStream(OutStr);
        Report.SaveAs(Entry."Report ID", Entry.GetRequestParameters(), OutputFormat(Entry), OutStr);
        TempBlob.CreateInStream(InStr);

        Prefix := Entry."File Name Prefix";
        if Prefix = '' then
            Prefix := Entry.Code;
        FileName := Prefix + '_' + Format(Today(), 0, '<Year4><Month,2><Day,2>') + FileExtension(Entry);

        EmailMessage.Create(Entry.Recipients, StrSubstNo(DefaultIfBlank(Entry.Subject, Entry.Description), Format(Today())),
            DefaultIfBlank(Entry.Body, 'Please find the attached report.'), true);
        EmailMessage.AddAttachment(CopyStr(FileName, 1, 250), MimeType(Entry), InStr);

        Entry.Get(EntryCode);
        Entry."Last Sent At" := CurrentDateTime();
        if Email.Send(EmailMessage, Enum::"Email Scenario"::Default) then
            Entry."Last Result" := 'Sent'
        else
            Entry."Last Result" := CopyStr(StrSubstNo(SendFailedErr, GetLastErrorText()), 1, MaxStrLen(Entry."Last Result"));
        Entry.Modify();
        Commit();
        if Entry."Last Result" <> 'Sent' then
            Error('%1', Entry."Last Result"); // let the Job Queue log the failure
    end;

    local procedure OutputFormat(Entry: Record "MID Scheduled Report"): ReportFormat
    begin
        case Entry."Output Format" of
            Entry."Output Format"::Excel:
                exit(ReportFormat::Excel);
            Entry."Output Format"::Word:
                exit(ReportFormat::Word);
        end;
        exit(ReportFormat::Pdf);
    end;

    local procedure FileExtension(Entry: Record "MID Scheduled Report"): Text
    begin
        case Entry."Output Format" of
            Entry."Output Format"::Excel:
                exit('.xlsx');
            Entry."Output Format"::Word:
                exit('.docx');
        end;
        exit('.pdf');
    end;

    local procedure MimeType(Entry: Record "MID Scheduled Report"): Text
    begin
        case Entry."Output Format" of
            Entry."Output Format"::Excel:
                exit('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
            Entry."Output Format"::Word:
                exit('application/vnd.openxmlformats-officedocument.wordprocessingml.document');
        end;
        exit('application/pdf');
    end;

    local procedure DefaultIfBlank(Value: Text; Default: Text): Text
    begin
        if Value <> '' then
            exit(Value);
        exit(Default);
    end;
}

permissionset 50190 "MID SCHED REPORTS"
{
    Assignable = true;
    Caption = 'Scheduled Report Emailer';
    IncludedPermissionSets = "Email - Edit";
    Permissions =
        tabledata "MID Scheduled Report" = RIMD,
        table "MID Scheduled Report" = X,
        page "MID Scheduled Reports" = X,
        codeunit "MID Send Scheduled Report" = X,
        tabledata "Job Queue Entry" = RIM;
}
