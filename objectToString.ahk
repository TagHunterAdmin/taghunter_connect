ObjectToString(obj, indent:="", lvl:=1) {
	if IsObject(obj) {
        If !(obj is Array || obj is Map || obj is String || obj is Number || obj is Object)
			throw Error("Object type not supported.", -1, Format("<Object at 0x{:p}>", ObjPtr(obj)))

		if IsInteger(indent)
		{
			if (indent < 0)
				throw Error("Indent parameter must be a postive integer.", -1, indent)
			spaces := indent, indent := ""

			Loop spaces ; ===> changed
				indent .= " "
		}
		indt := ""

		Loop indent ? lvl : 0
			indt .= indent

        is_array := (obj is Array)

		lvl += 1, out := "" ; Make #Warn happy

		if (type(obj) = "Map"){
			for k, v in obj {
				out .= '"' k '",' ObjectToString(v, indent, lvl) . ( indent ? ",`n" . indt : "," )

			}
		} else if (type(obj) = "Array"){
			for k, v in obj {
				if IsObject(k) || (k == "")
					throw Error("Invalid object key.", -1, k ? Format("<Object at 0x{:p}>", ObjPtr(obj)) : "<blank>")

				out .= ObjectToString(v, indent, lvl) ; value
					.  ( indent ? ",`n" . indt : "," ) ; token + indent
			}
		}  else if (type(obj) = "Object"){
			for k, v in obj.OwnProps() {
				if IsObject(k) || (k == "")
					throw Error("Invalid object key.", -1, k ? Format("<Object at 0x{:p}>", ObjPtr(obj)) : "<blank>")
				out .= k ":" ObjectToString(v, indent, lvl) . ( indent ? ",`n" . indt : "," )
			}
		}


		if (out != "") {
			out := Trim(out, ",`n" . indent)
			if (indent != "")
				out := "`n" . indt . out . "`n" . SubStr(indt, StrLen(indent)+1)
		}
		if (type(obj) = "Map"){
			return "Map(" out ")"
		} else if (type(obj) = "Array"){
			return "[" out "]"
		} else {
			return "{" . out . "}"
		}
		return out
    } Else If (obj is Number)
        return obj

    Else ; String
        return escape_str(obj)

    escape_str(obj) {
        obj := StrReplace(obj,"\","\\")
        obj := StrReplace(obj,"`t","\t")
        obj := StrReplace(obj,"`r","\r")
        obj := StrReplace(obj,"`n","\n")
        obj := StrReplace(obj,"`b","\b")
        obj := StrReplace(obj,"`f","\f")
        obj := StrReplace(obj,"/","\/")
        obj := StrReplace(obj,'"','\"')

        return '"' obj '"'
    }
}