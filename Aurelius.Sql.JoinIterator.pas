unit Aurelius.Sql.JoinIterator;

interface

uses
  System.SysUtils,
  Aurelius.Sql.BaseTypes;

type
  TNodeInfo = record
    Join: TSQLJoin;
    Left: TSQLTable;
  end;

  TNodeHandler = reference to procedure (AJoin: TSQLJoin; ALeft, ARight: TSQLTable);

  TJoinIterator = class
  private
    FJoin: TSQLJoin;
  public
    constructor Create(AJoin: TSQLJoin);
    procedure ForEachDo(AHandler: TNodeHandler);
  end;

implementation

uses
  Generics.Collections;

type
  TNodeStack = TStack<TNodeInfo>;

function FindLeftTable(AJoin: TSQLJoin; AStack: TNodeStack): TSQLTable;
var
  Node: TNodeInfo;
  C, I: Integer;
begin
  C := AStack.Count;
  Node.Join := AJoin;
  repeat
    AStack.Push(Node);
    if Node.Join.LeftRelation is TSQLTable then
    begin
      Result := TSQLTable(Node.Join.LeftRelation);
      Break;
    end else
      Node.Join := TSQLJoin(Node.Join.LeftRelation);
  until False;
  for I := Pred(AStack.Count) downto C do
    AStack.List[I].Left := Result;
end;

{ TJoinIterator }

constructor TJoinIterator.Create(AJoin: TSQLJoin);
begin
  inherited Create;
  if AJoin=nil then
    raise Exception.Create('Join is required');
  FJoin := AJoin;
end;

procedure TJoinIterator.ForEachDo(AHandler: TNodeHandler);
var
  Node: TNodeInfo;
  Stack: TNodeStack;
  Table: TSQLTable;
begin
  if not Assigned(AHandler) then
    Exit;
  Stack := TNodeStack.Create;
  try
    Table := FindLeftTable(FJoin, Stack);
    AHandler(nil, Table, nil);
    while Stack.Count>0 do
    begin
      Node := Stack.Pop;
      if Node.Join.RightRelation is TSQLTable then
        Table := TSQLTable(Node.Join.RightRelation)
      else
        Table := FindLeftTable(TSQLJoin(Node.Join.RightRelation), Stack);
      AHandler(Node.Join, Node.Left, Table);
    end;
  finally
    Stack.Free;
  end;
end;

end.
