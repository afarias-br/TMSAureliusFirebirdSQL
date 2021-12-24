unit Aurelius.Sql.JoinIterator;

interface

uses
  SysUtils,
  Aurelius.Sql.BaseTypes;

type
  TJoinNode = record
    Join: TSQLJoin;
    RightTable: TSQLTable;
    LeftTable: TSQLTable;
    constructor Init(AJoin: TSQLJoin);
  end;

  TNodeHandler = reference to procedure (ANode: TJoinNode);

  TJoinIterator = class
  private
    FRoot: TSQLJoin;
  public
    constructor Create(ARoot: TSQLJoin);
    procedure ForEachDo(AHandler: TNodeHandler);
  end;

implementation

uses
  Generics.Collections;

type
  TNodeStack = TStack<TJoinNode>;

{ TJoinIterator }

constructor TJoinIterator.Create(ARoot: TSQLJoin);
begin
  inherited Create;
  if ARoot=nil then
    raise Exception.Create('Join is required');
  FRoot := ARoot;
end;

procedure TJoinIterator.ForEachDo(AHandler: TNodeHandler);

function FindJoinedTable(AJoin: TSQLJoin; AStack: TNodeStack): TSQLTable;
var
  Node: TJoinNode;
  C, I: Integer;
begin
  C := AStack.Count;
  Node.Init(AJoin);
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
    AStack.List[I].LeftTable := Result;
end;

var
  Node: TJoinNode;
  Stack: TNodeStack;
begin
  if not Assigned(AHandler) then
    Exit;
  Stack := TNodeStack.Create;
  try
    Node.Init(nil);
    Node.LeftTable := FindJoinedTable(FRoot, Stack); // the first/main table
    AHandler(Node);
    while Stack.Count>0 do
    begin
      Node := Stack.Pop;
      if Node.Join.RightRelation is TSQLTable then
        Node.RightTable := TSQLTable(Node.Join.RightRelation)
      else
        Node.RightTable := FindJoinedTable(TSQLJoin(Node.Join.RightRelation), Stack);
      AHandler(Node);
    end;
  finally
    Stack.Free;
  end;
end;

{ TJoinNode }

constructor TJoinNode.Init(AJoin: TSQLJoin);
begin
  Join := AJoin;
  LeftTable := nil;
  RightTable := nil;
end;

end.
