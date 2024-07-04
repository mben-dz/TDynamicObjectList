unit API.Generics;

interface
uses
  System.Classes
//
, System.Generics.Collections
, System.Generics.Defaults
  ;

type
  TSort = (sNone, sAsc, sDes);

  TDynamicObjectList<T: class> = class(TObjectList<T>)
  private
    fComparer: TComparison<T>;
    fSortField: string;
    fSort: TSort;
    function CompareNumbers(const L, R: Integer): Integer;
    function CompareObjects(const aLeft, aRight: T): Integer;
  public
    constructor CreateWithSort(const aSortField: string; aSort: TSort = sAsc);
    procedure Sort(aSort: TSort = sAsc);
    function IsSortedCorrectly: Boolean;
  end;

implementation

uses
  System.SysUtils
, System.Rtti
, System.TypInfo
  ;

{ TDynamicObjectList<T> }

constructor TDynamicObjectList<T>.CreateWithSort(const aSortField: string; aSort: TSort);
begin inherited Create(True);

  fSortField := aSortField;
  fSort      := aSort;

  fComparer  := CompareObjects;
end;

function TDynamicObjectList<T>.CompareNumbers(const L, R: Integer): Integer;
begin
  Result := L - R;
end;

function TDynamicObjectList<T>.CompareObjects(const aLeft, aRight: T): Integer;
var
  L_Ctx       : TRttiContext;
  L_Typ       : TRttiType;
  L_Prop      : TRttiProperty;
  L_Left      : TClass absolute aLeft;
  L_Right     : TClass absolute aRight;

  L_LeftValue,
  L_RightValue: TValue;
begin
  if fSortField = '' then
  begin
    // Use default comparer if no specific field is specified ..
    Result := TComparer<T>.Default.Compare(T(L_Left), T(L_Right));
    Exit;
  end;

  L_Ctx := TRttiContext.Create;
  try
    L_Typ  := L_Ctx.GetType(T); // Get RTTI for type ( T )
    L_Prop := nil;
    L_Prop := L_Typ.GetProperty(fSortField);

    if Assigned(L_Prop) then
    begin
      L_LeftValue    := L_Prop.GetValue(L_Left);
      L_RightValue   := L_Prop.GetValue(L_Right);

      case L_LeftValue.Kind of
       tkInteger, tkInt64:
         case fSort of
           sAsc: Result := CompareNumbers(L_LeftValue.AsInteger, L_RightValue.AsInteger);
           sDes: Result := CompareNumbers(L_RightValue.AsInteger, L_LeftValue.AsInteger);
         else
          Result := TComparer<T>.Default.Compare(T(L_Left), T(L_Right));
         end;
       tkString, tkWString, tkLString, tkUString:
         case fSort of
           sAsc: Result := CompareNumbers(Integer.Parse(L_LeftValue.AsString),
                                          Integer.Parse(L_RightValue.AsString));
           sDes: Result := CompareNumbers(Integer.Parse(L_LeftValue.AsString),
                                          Integer.Parse(L_RightValue.AsString));
         else
           Result := TComparer<T>.Default.Compare(T(L_Left), T(L_Right));
         end;
      else
        TComparer<T>.Default.Compare(T(L_Left), T(L_Right));
      end;
    end
    else
      Result := 0; // Handle case where property is not found
  finally
    L_Ctx.Free;
  end;
end;

function TDynamicObjectList<T>.IsSortedCorrectly: Boolean;
var
  I: Integer;
begin
  Result := True;
  for I := 1 to Count - 1 do
  begin
    if CompareObjects(Items[I - 1], Items[I]) > 0 then
    begin
      Result := False;
      Break;
    end;
  end;
end;

procedure TDynamicObjectList<T>.Sort(aSort: TSort);
begin
  fSort := aSort;

  inherited Sort(TComparer<T>.Construct(fComparer));
end;

end.
