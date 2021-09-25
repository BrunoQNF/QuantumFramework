Package["QuantumFramework`"]

PackageExport["QuditBasisName"]



QuditBasisName["Properties"] = {"Name", "DualQ", "Dual", "Qudits"}

$QuditZero = CircleTimes[]

$QuditIdentity = \[FormalCapitalI]


nameHeadQ[name_] := MatchQ[name, _TensorProduct | _CircleTimes | _List]


nameLength[name_ ? nameHeadQ] := Length @ name

nameLength[_] := 1


simplifyName[name_] := With[{
    noIdentities = DeleteCases[name, $QuditIdentity]
},
    If[ nameHeadQ[noIdentities],
        If[ nameLength[noIdentities] == 1,
            First[noIdentities, $QuditIdentity],
            If[ nameLength[noIdentities] == 0 && nameLength[name] > 0,
                $QuditIdentity,
                noIdentities
            ]
        ]
    ]
]

Options[QuditBasisName] = {"Dual" -> False}

QuditBasisName[QuditBasisName[names__, opts : OptionsPattern[QuditBasisName]], newOpts : OptionsPattern[]] :=
    QuditBasisName[names, Sequence @@ DeleteDuplicatesBy[{newOpts, opts}, First]]

QuditBasisName[] := QuditBasisName[$QuditIdentity]

QuditBasisName[{}] := QuditBasisName[$QuditZero]

QuditBasisName[name_] := QuditBasisName[name, "Dual" -> False]

_QuditBasisName["Properties"] := QuditBasisName["Properties"]

QuditBasisName[name_, OptionsPattern[QuditBasisName]]["Name"] := name

QuditBasisName[names__, OptionsPattern[QuditBasisName]]["Name"] := {names}

qbn_QuditBasisName["DualQ"] := TrueQ[Lookup[Options[qbn], "Dual", False]]

qbn_QuditBasisName["Dual"] := QuditBasisName[qbn, "Dual" -> Not @ qbn["DualQ"]]

qbn_QuditBasisName["Qudits"] := Length @ DeleteCases[QuditBasisName[$QuditIdentity, ___]] @ Normal @ qbn

qbn_QuditBasisName["Pretty"] := simplifyName[CircleTimes @@ Normal[qbn]]


splitQuditBasisName[QuditBasisName[name_ ? nameHeadQ, args___]] :=
    Catenate[If[nameLength[#] > 1, splitQuditBasisName, List] @ QuditBasisName[#, args] & /@ (List @@ name)]

splitQuditBasisName[qbn : QuditBasisName[_, OptionsPattern[]]] := {qbn}

splitQuditBasisName[qbn : QuditBasisName[names___, OptionsPattern[]]] :=
    Catenate[splitQuditBasisName @* If[qbn["DualQ"], QuditBasisName[#]["Dual"] &, QuditBasisName] /@ {names}]

QuditBasisName /: Normal[qbn_QuditBasisName] := splitQuditBasisName @ qbn


groupQuditBasisName[qbn_QuditBasisName] := QuditBasisName @@
    SequenceReplace[Normal[qbn],
        qbns : {Repeated[_QuditBasisName, {2, Infinity}]} /; Equal @@ (#["DualQ"] & /@ qbns) :>
            QuditBasisName[Flatten[#["Name"] & /@ qbns], "Dual" -> First[qbns]["DualQ"]]
]

qbn_QuditBasisName["Group"] := groupQuditBasisName @ qbn

qbn_QuditBasisName[{"Permute", perm_Cycles}] := (QuditBasisName @@ Permute[Normal[qbn], perm])["Group"]

qbn_QuditBasisName["Take", arg_] := (QuditBasisName @@ Take[Normal[qbn], arg])["Group"]

qbn_QuditBasisName["Drop", arg_] := (QuditBasisName @@ Drop[Normal[qbn], arg])["Group"]

qbn_QuditBasisName["Delete", arg_] := (QuditBasisName @@ Delete[Normal[qbn], arg])["Group"]


QuantumTensorProduct[qbn1_QuditBasisName, qbn2_QuditBasisName] := Which[
    qbn1["Name"] === $QuditZero || qbn2["Name"] === $QuditZero,
    QuditBasisName[$QuditZero],
    qbn1["Name"] === $QuditIdentity,
    qbn2,
    qbn2["Name"] === $QuditIdentity,
    qbn1,
    qbn1["DualQ"] === qbn2["DualQ"],
    QuditBasisName[Flatten @ {qbn1["Name"], qbn2["Name"]}, "Dual" -> qbn1["DualQ"]],
    True,
    QuditBasisName[qbn1, qbn2]
]["Group"]


QuditBasisName /: MakeBoxes[qbn : QuditBasisName[name_, OptionsPattern[]], format_] := With[{
    boxes = Switch[name, $QuditZero, "\[EmptySet]", $QuditIdentity, "\[ScriptOne]", _,
            TemplateBox[{RowBox[Riffle[ToBoxes[#, format] & /@ {##}, "\[InvisibleSpace]"]]}, If[qbn["DualQ"], "Bra", "Ket"]] & @@
                If[qbn["Qudits"] > 1, name, {name}]]
},
    InterpretationBox[boxes, qbn]
]

QuditBasisName /: MakeBoxes[qbn : QuditBasisName[names__, OptionsPattern[]], format_] :=
    ToBoxes[Interpretation[Row @ If[qbn["DualQ"], Map[#["Dual"] &], Identity] @ {names}, qbn], format]

