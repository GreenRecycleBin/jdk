//
// Copyright (c) 2020, 2021, Oracle and/or its affiliates. All rights reserved.
// Copyright (c) 2020, 2021, Arm Limited. All rights reserved.
// DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.
//
// This code is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License version 2 only, as
// published by the Free Software Foundation.
//
// This code is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
// version 2 for more details (a copy is included in the LICENSE file that
// accompanied this code).
//
// You should have received a copy of the GNU General Public License version
// 2 along with this work; if not, write to the Free Software Foundation,
// Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA.
//
// Please contact Oracle, 500 Oracle Parkway, Redwood Shores, CA 94065 USA
// or visit www.oracle.com if you need additional information or have any
// questions.
//
//

dnl Generate the warning
// This file is automatically generated by running "m4 aarch64_sve_ad.m4". Do not edit ----
dnl

// AArch64 SVE Architecture Description File


// 4 bit signed offset -- for predicated load/store
dnl
dnl OPERAND_VMEMORYA_IMMEDIATE_OFFSET($1,            $2,       $3     )
dnl OPERAND_VMEMORYA_IMMEDIATE_OFFSET(imm_type_abbr, imm_type, imm_len)
define(`OPERAND_VMEMORYA_IMMEDIATE_OFFSET', `
operand vmemA_imm$1Offset$3()
%{
  predicate(Address::offset_ok_for_sve_immed(n->get_$2(), $3,
            Matcher::scalable_vector_reg_size(T_BYTE)));
  match(Con$1);

  op_cost(0);
  format %{ %}
  interface(CONST_INTER);
%}')dnl
OPERAND_VMEMORYA_IMMEDIATE_OFFSET(I, int,  4)
OPERAND_VMEMORYA_IMMEDIATE_OFFSET(L, long, 4)
dnl
dnl OPERAND_VMEMORYA_INDIRECT_OFFSET($1,            $2     )
dnl OPERAND_VMEMORYA_INDIRECT_OFFSET(imm_type_abbr, imm_len)
define(`OPERAND_VMEMORYA_INDIRECT_OFFSET', `
operand vmemA_indOff$1$2(iRegP reg, vmemA_imm$1Offset$2 off)
%{
  constraint(ALLOC_IN_RC(ptr_reg));
  match(AddP reg off);
  op_cost(0);
  format %{ "[$reg, $off, MUL VL]" %}
  interface(MEMORY_INTER) %{
    base($reg);
    `index'(0xffffffff);
    scale(0x0);
    disp($off);
  %}
%}')dnl
OPERAND_VMEMORYA_INDIRECT_OFFSET(I, 4)
OPERAND_VMEMORYA_INDIRECT_OFFSET(L, 4)

opclass vmemA(indirect, vmemA_indOffI4, vmemA_indOffL4);

source_hpp %{
  bool op_sve_supported(int opcode);
%}

source %{
  static inline BasicType vector_element_basic_type(const MachNode* n) {
    const TypeVect* vt = n->bottom_type()->is_vect();
    return vt->element_basic_type();
  }

  static inline BasicType vector_element_basic_type(const MachNode* use, const MachOper* opnd) {
    int def_idx = use->operand_index(opnd);
    Node* def = use->in(def_idx);
    const TypeVect* vt = def->bottom_type()->is_vect();
    return vt->element_basic_type();
  }

  static Assembler::SIMD_RegVariant elemBytes_to_regVariant(int esize) {
    switch(esize) {
      case 1:
        return Assembler::B;
      case 2:
        return Assembler::H;
      case 4:
        return Assembler::S;
      case 8:
        return Assembler::D;
      default:
        assert(false, "unsupported");
        ShouldNotReachHere();
    }
    return Assembler::INVALID;
  }

  static Assembler::SIMD_RegVariant elemType_to_regVariant(BasicType bt) {
    return elemBytes_to_regVariant(type2aelembytes(bt));
  }

  typedef void (C2_MacroAssembler::* sve_mem_insn_predicate)(FloatRegister Rt, Assembler::SIMD_RegVariant T,
                                                             PRegister Pg, const Address &adr);

  // Predicated load/store, with optional ptrue to all elements of given predicate register.
  static void loadStoreA_predicate(C2_MacroAssembler masm, bool is_store,
                                   FloatRegister reg, PRegister pg, BasicType bt,
                                   int opcode, Register base, int index, int size, int disp) {
    sve_mem_insn_predicate insn;
    Assembler::SIMD_RegVariant type;
    int esize = type2aelembytes(bt);
    if (index == -1) {
      assert(size == 0, "unsupported address mode: scale size = %d", size);
      switch(esize) {
      case 1:
        insn = is_store ? &C2_MacroAssembler::sve_st1b : &C2_MacroAssembler::sve_ld1b;
        type = Assembler::B;
        break;
      case 2:
        insn = is_store ? &C2_MacroAssembler::sve_st1h : &C2_MacroAssembler::sve_ld1h;
        type = Assembler::H;
        break;
      case 4:
        insn = is_store ? &C2_MacroAssembler::sve_st1w : &C2_MacroAssembler::sve_ld1w;
        type = Assembler::S;
        break;
      case 8:
        insn = is_store ? &C2_MacroAssembler::sve_st1d : &C2_MacroAssembler::sve_ld1d;
        type = Assembler::D;
        break;
      default:
        assert(false, "unsupported");
        ShouldNotReachHere();
      }
      (masm.*insn)(reg, type, pg, Address(base, disp / Matcher::scalable_vector_reg_size(T_BYTE)));
    } else {
      assert(false, "unimplemented");
      ShouldNotReachHere();
    }
  }

  bool op_sve_supported(int opcode) {
    switch (opcode) {
      case Op_MulAddVS2VI:
        // No multiply reduction instructions
      case Op_MulReductionVD:
      case Op_MulReductionVF:
      case Op_MulReductionVI:
      case Op_MulReductionVL:
        // Others
      case Op_Extract:
      case Op_ExtractB:
      case Op_ExtractC:
      case Op_ExtractD:
      case Op_ExtractF:
      case Op_ExtractI:
      case Op_ExtractL:
      case Op_ExtractS:
      case Op_ExtractUB:
      // Vector API specific
      case Op_AndReductionV:
      case Op_OrReductionV:
      case Op_XorReductionV:
      case Op_MaxReductionV:
      case Op_MinReductionV:
      case Op_LoadVectorGather:
      case Op_StoreVectorScatter:
      case Op_VectorBlend:
      case Op_VectorCast:
      case Op_VectorCastB2X:
      case Op_VectorCastD2X:
      case Op_VectorCastF2X:
      case Op_VectorCastI2X:
      case Op_VectorCastL2X:
      case Op_VectorCastS2X:
      case Op_VectorInsert:
      case Op_VectorLoadConst:
      case Op_VectorLoadMask:
      case Op_VectorLoadShuffle:
      case Op_VectorMaskCmp:
      case Op_VectorRearrange:
      case Op_VectorReinterpret:
      case Op_VectorStoreMask:
      case Op_VectorTest:
        return false;
      default:
        return true;
    }
  }
%}

definitions %{
  int_def SVE_COST             (200, 200);
%}

dnl
dnl ELEMENT_SHORT_CHART($1, $2)
dnl ELEMENT_SHORT_CHART(etype, node)
define(`ELEMENT_SHORT_CHAR',`ifelse(`$1', `T_SHORT',
  `($2->bottom_type()->is_vect()->element_basic_type() == T_SHORT ||
            ($2->bottom_type()->is_vect()->element_basic_type() == T_CHAR))',
   `($2->bottom_type()->is_vect()->element_basic_type() == $1)')')dnl
dnl

// All SVE instructions

// vector load/store

// Use predicated vector load/store
instruct loadV(vReg dst, vmemA mem) %{
  predicate(UseSVE > 0 && n->as_LoadVector()->memory_size() >= 16);
  match(Set dst (LoadVector mem));
  ins_cost(SVE_COST);
  format %{ "sve_ldr $dst, $mem\t # vector (sve)" %}
  ins_encode %{
    FloatRegister dst_reg = as_FloatRegister($dst$$reg);
    loadStoreA_predicate(C2_MacroAssembler(&cbuf), false, dst_reg, ptrue,
                         vector_element_basic_type(this), $mem->opcode(),
                         as_Register($mem$$base), $mem$$index, $mem$$scale, $mem$$disp);
  %}
  ins_pipe(pipe_slow);
%}

instruct storeV(vReg src, vmemA mem) %{
  predicate(UseSVE > 0 && n->as_StoreVector()->memory_size() >= 16);
  match(Set mem (StoreVector mem src));
  ins_cost(SVE_COST);
  format %{ "sve_str $mem, $src\t # vector (sve)" %}
  ins_encode %{
    FloatRegister src_reg = as_FloatRegister($src$$reg);
    loadStoreA_predicate(C2_MacroAssembler(&cbuf), true, src_reg, ptrue,
                         vector_element_basic_type(this, $src), $mem->opcode(),
                         as_Register($mem$$base), $mem$$index, $mem$$scale, $mem$$disp);
  %}
  ins_pipe(pipe_slow);
%}

dnl
dnl UNARY_OP_TRUE_PREDICATE_ETYPE($1,        $2,      $3,           $4,   $5,          %6  )
dnl UNARY_OP_TRUE_PREDICATE_ETYPE(insn_name, op_name, element_type, size, min_vec_len, insn)
define(`UNARY_OP_TRUE_PREDICATE_ETYPE', `
instruct $1(vReg dst, vReg src) %{
  predicate(UseSVE > 0 && n->as_Vector()->length() >= $5 &&
            n->bottom_type()->is_vect()->element_basic_type() == $3);
  match(Set dst ($2 src));
  ins_cost(SVE_COST);
  format %{ "$6 $dst, $src\t# vector (sve) ($4)" %}
  ins_encode %{
    __ $6(as_FloatRegister($dst$$reg), __ $4,
         ptrue, as_FloatRegister($src$$reg));
  %}
  ins_pipe(pipe_slow);
%}')dnl
dnl
// vector abs
UNARY_OP_TRUE_PREDICATE_ETYPE(vabsB, AbsVB, T_BYTE,   B, 16, sve_abs)
UNARY_OP_TRUE_PREDICATE_ETYPE(vabsS, AbsVS, T_SHORT,  H, 8,  sve_abs)
UNARY_OP_TRUE_PREDICATE_ETYPE(vabsI, AbsVI, T_INT,    S, 4,  sve_abs)
UNARY_OP_TRUE_PREDICATE_ETYPE(vabsL, AbsVL, T_LONG,   D, 2,  sve_abs)
UNARY_OP_TRUE_PREDICATE_ETYPE(vabsF, AbsVF, T_FLOAT,  S, 4,  sve_fabs)
UNARY_OP_TRUE_PREDICATE_ETYPE(vabsD, AbsVD, T_DOUBLE, D, 2,  sve_fabs)
dnl
dnl BINARY_OP_UNPREDICATED($1,        $2       $3,   $4           $5  )
dnl BINARY_OP_UNPREDICATED(insn_name, op_name, size, min_vec_len, insn)
define(`BINARY_OP_UNPREDICATED', `
instruct $1(vReg dst, vReg src1, vReg src2) %{
  predicate(UseSVE > 0 && n->as_Vector()->length() >= $4);
  match(Set dst ($2 src1 src2));
  ins_cost(SVE_COST);
  format %{ "$5 $dst, $src1, $src2\t # vector (sve) ($3)" %}
  ins_encode %{
    __ $5(as_FloatRegister($dst$$reg), __ $3,
         as_FloatRegister($src1$$reg),
         as_FloatRegister($src2$$reg));
  %}
  ins_pipe(pipe_slow);
%}')dnl

// vector add
BINARY_OP_UNPREDICATED(vaddB, AddVB, B, 16, sve_add)
BINARY_OP_UNPREDICATED(vaddS, AddVS, H, 8,  sve_add)
BINARY_OP_UNPREDICATED(vaddI, AddVI, S, 4,  sve_add)
BINARY_OP_UNPREDICATED(vaddL, AddVL, D, 2,  sve_add)
BINARY_OP_UNPREDICATED(vaddF, AddVF, S, 4,  sve_fadd)
BINARY_OP_UNPREDICATED(vaddD, AddVD, D, 2,  sve_fadd)
dnl
dnl BINARY_OP_UNSIZED($1,        $2,      $3,          $4  )
dnl BINARY_OP_UNSIZED(insn_name, op_name, min_vec_len, insn)
define(`BINARY_OP_UNSIZED', `
instruct $1(vReg dst, vReg src1, vReg src2) %{
  predicate(UseSVE > 0 && n->as_Vector()->length_in_bytes() >= $3);
  match(Set dst ($2 src1 src2));
  ins_cost(SVE_COST);
  format %{ "$4  $dst, $src1, $src2\t# vector (sve)" %}
  ins_encode %{
    __ $4(as_FloatRegister($dst$$reg),
         as_FloatRegister($src1$$reg),
         as_FloatRegister($src2$$reg));
  %}
  ins_pipe(pipe_slow);
%}')dnl

// vector and
BINARY_OP_UNSIZED(vand, AndV, 16, sve_and)

// vector or
BINARY_OP_UNSIZED(vor, OrV, 16, sve_orr)

// vector xor
BINARY_OP_UNSIZED(vxor, XorV, 16, sve_eor)

// vector not
dnl
define(`MATCH_RULE', `ifelse($1, I,
`match(Set dst (XorV src (ReplicateB m1)));
  match(Set dst (XorV src (ReplicateS m1)));
  match(Set dst (XorV src (ReplicateI m1)));',
`match(Set dst (XorV src (ReplicateL m1)));')')dnl
dnl
define(`VECTOR_NOT', `
instruct vnot$1`'(vReg dst, vReg src, imm$1_M1 m1) %{
  predicate(UseSVE > 0 && n->as_Vector()->length_in_bytes() >= 16);
  MATCH_RULE($1)
  ins_cost(SVE_COST);
  format %{ "sve_not $dst, $src\t# vector (sve) $2" %}
  ins_encode %{
    __ sve_not(as_FloatRegister($dst$$reg), __ D,
               ptrue, as_FloatRegister($src$$reg));
  %}
  ins_pipe(pipe_slow);
%}')dnl
dnl        $1,$2
VECTOR_NOT(I, B/H/S)
VECTOR_NOT(L, D)
undefine(MATCH_RULE)

// vector and_not
dnl
define(`MATCH_RULE', `ifelse($1, I,
`match(Set dst (AndV src1 (XorV src2 (ReplicateB m1))));
  match(Set dst (AndV src1 (XorV src2 (ReplicateS m1))));
  match(Set dst (AndV src1 (XorV src2 (ReplicateI m1))));',
`match(Set dst (AndV src1 (XorV src2 (ReplicateL m1))));')')dnl
dnl
define(`VECTOR_AND_NOT', `
instruct vand_not$1`'(vReg dst, vReg src1, vReg src2, imm$1_M1 m1) %{
  predicate(UseSVE > 0 && n->as_Vector()->length_in_bytes() >= 16);
  MATCH_RULE($1)
  ins_cost(SVE_COST);
  format %{ "sve_bic $dst, $src1, $src2\t# vector (sve) $2" %}
  ins_encode %{
    __ sve_bic(as_FloatRegister($dst$$reg),
               as_FloatRegister($src1$$reg),
               as_FloatRegister($src2$$reg));
  %}
  ins_pipe(pipe_slow);
%}')dnl
dnl            $1,$2
VECTOR_AND_NOT(I, B/H/S)
VECTOR_AND_NOT(L, D)
undefine(MATCH_RULE)
dnl
dnl VDIVF($1,          $2  , $3         )
dnl VDIVF(name_suffix, size, min_vec_len)
define(`VDIVF', `
instruct vdiv$1(vReg dst_src1, vReg src2) %{
  predicate(UseSVE > 0 && n->as_Vector()->length() >= $3);
  match(Set dst_src1 (DivV$1 dst_src1 src2));
  ins_cost(SVE_COST);
  format %{ "sve_fdiv  $dst_src1, $dst_src1, $src2\t# vector (sve) ($2)" %}
  ins_encode %{
    __ sve_fdiv(as_FloatRegister($dst_src1$$reg), __ $2,
         ptrue, as_FloatRegister($src2$$reg));
  %}
  ins_pipe(pipe_slow);
%}')dnl

// vector float div
VDIVF(F, S, 4)
VDIVF(D, D, 2)

// vector min/max

instruct vmin(vReg dst_src1, vReg src2) %{
  predicate(UseSVE > 0 && n->as_Vector()->length_in_bytes() >= 16);
  match(Set dst_src1 (MinV dst_src1 src2));
  ins_cost(SVE_COST);
  format %{ "sve_min $dst_src1, $dst_src1, $src2\t # vector (sve)" %}
  ins_encode %{
    BasicType bt = vector_element_basic_type(this);
    Assembler::SIMD_RegVariant size = elemType_to_regVariant(bt);
    if (is_floating_point_type(bt)) {
      __ sve_fmin(as_FloatRegister($dst_src1$$reg), size,
                  ptrue, as_FloatRegister($src2$$reg));
    } else {
      assert(is_integral_type(bt), "Unsupported type");
      __ sve_smin(as_FloatRegister($dst_src1$$reg), size,
                  ptrue, as_FloatRegister($src2$$reg));
    }
  %}
  ins_pipe(pipe_slow);
%}

instruct vmax(vReg dst_src1, vReg src2) %{
  predicate(UseSVE > 0 && n->as_Vector()->length_in_bytes() >= 16);
  match(Set dst_src1 (MaxV dst_src1 src2));
  ins_cost(SVE_COST);
  format %{ "sve_max $dst_src1, $dst_src1, $src2\t # vector (sve)" %}
  ins_encode %{
    BasicType bt = vector_element_basic_type(this);
    Assembler::SIMD_RegVariant size = elemType_to_regVariant(bt);
    if (is_floating_point_type(bt)) {
      __ sve_fmax(as_FloatRegister($dst_src1$$reg), size,
                  ptrue, as_FloatRegister($src2$$reg));
    } else {
      assert(is_integral_type(bt), "Unsupported type");
      __ sve_smax(as_FloatRegister($dst_src1$$reg), size,
                  ptrue, as_FloatRegister($src2$$reg));
    }
  %}
  ins_pipe(pipe_slow);
%}

dnl
dnl VFMLA($1           $2    $3         )
dnl VFMLA(name_suffix, size, min_vec_len)
define(`VFMLA', `
// dst_src1 = dst_src1 + src2 * src3
instruct vfmla$1(vReg dst_src1, vReg src2, vReg src3) %{
  predicate(UseFMA && UseSVE > 0 && n->as_Vector()->length() >= $3);
  match(Set dst_src1 (FmaV$1 dst_src1 (Binary src2 src3)));
  ins_cost(SVE_COST);
  format %{ "sve_fmla $dst_src1, $src2, $src3\t # vector (sve) ($2)" %}
  ins_encode %{
    __ sve_fmla(as_FloatRegister($dst_src1$$reg), __ $2,
         ptrue, as_FloatRegister($src2$$reg), as_FloatRegister($src3$$reg));
  %}
  ins_pipe(pipe_slow);
%}')dnl
dnl
// vector fmla
VFMLA(F, S, 4)
VFMLA(D, D, 2)

dnl
dnl VFMLS($1           $2    $3         )
dnl VFMLS(name_suffix, size, min_vec_len)
define(`VFMLS', `
// dst_src1 = dst_src1 + -src2 * src3
// dst_src1 = dst_src1 + src2 * -src3
instruct vfmls$1(vReg dst_src1, vReg src2, vReg src3) %{
  predicate(UseFMA && UseSVE > 0 && n->as_Vector()->length() >= $3);
  match(Set dst_src1 (FmaV$1 dst_src1 (Binary (NegV$1 src2) src3)));
  match(Set dst_src1 (FmaV$1 dst_src1 (Binary src2 (NegV$1 src3))));
  ins_cost(SVE_COST);
  format %{ "sve_fmls $dst_src1, $src2, $src3\t # vector (sve) ($2)" %}
  ins_encode %{
    __ sve_fmls(as_FloatRegister($dst_src1$$reg), __ $2,
         ptrue, as_FloatRegister($src2$$reg), as_FloatRegister($src3$$reg));
  %}
  ins_pipe(pipe_slow);
%}')dnl
dnl
// vector fmls
VFMLS(F, S, 4)
VFMLS(D, D, 2)

dnl
dnl VFNMLA($1           $2    $3         )
dnl VFNMLA(name_suffix, size, min_vec_len)
define(`VFNMLA', `
// dst_src1 = -dst_src1 + -src2 * src3
// dst_src1 = -dst_src1 + src2 * -src3
instruct vfnmla$1(vReg dst_src1, vReg src2, vReg src3) %{
  predicate(UseFMA && UseSVE > 0 && n->as_Vector()->length() >= $3);
  match(Set dst_src1 (FmaV$1 (NegV$1 dst_src1) (Binary (NegV$1 src2) src3)));
  match(Set dst_src1 (FmaV$1 (NegV$1 dst_src1) (Binary src2 (NegV$1 src3))));
  ins_cost(SVE_COST);
  format %{ "sve_fnmla $dst_src1, $src2, $src3\t # vector (sve) ($2)" %}
  ins_encode %{
    __ sve_fnmla(as_FloatRegister($dst_src1$$reg), __ $2,
         ptrue, as_FloatRegister($src2$$reg), as_FloatRegister($src3$$reg));
  %}
  ins_pipe(pipe_slow);
%}')dnl
dnl
// vector fnmla
VFNMLA(F, S, 4)
VFNMLA(D, D, 2)

dnl
dnl VFNMLS($1           $2    $3         )
dnl VFNMLS(name_suffix, size, min_vec_len)
define(`VFNMLS', `
// dst_src1 = -dst_src1 + src2 * src3
instruct vfnmls$1(vReg dst_src1, vReg src2, vReg src3) %{
  predicate(UseFMA && UseSVE > 0 && n->as_Vector()->length() >= $3);
  match(Set dst_src1 (FmaV$1 (NegV$1 dst_src1) (Binary src2 src3)));
  ins_cost(SVE_COST);
  format %{ "sve_fnmls $dst_src1, $src2, $src3\t # vector (sve) ($2)" %}
  ins_encode %{
    __ sve_fnmls(as_FloatRegister($dst_src1$$reg), __ $2,
         ptrue, as_FloatRegister($src2$$reg), as_FloatRegister($src3$$reg));
  %}
  ins_pipe(pipe_slow);
%}')dnl
dnl
// vector fnmls
VFNMLS(F, S, 4)
VFNMLS(D, D, 2)

dnl
dnl VMLA($1           $2    $3         )
dnl VMLA(name_suffix, size, min_vec_len)
define(`VMLA', `
// dst_src1 = dst_src1 + src2 * src3
instruct vmla$1(vReg dst_src1, vReg src2, vReg src3)
%{
  predicate(UseSVE > 0 && n->as_Vector()->length() >= $3);
  match(Set dst_src1 (AddV$1 dst_src1 (MulV$1 src2 src3)));
  ins_cost(SVE_COST);
  format %{ "sve_mla $dst_src1, src2, src3\t # vector (sve) ($2)" %}
  ins_encode %{
    __ sve_mla(as_FloatRegister($dst_src1$$reg), __ $2,
      ptrue, as_FloatRegister($src2$$reg), as_FloatRegister($src3$$reg));
  %}
  ins_pipe(pipe_slow);
%}')dnl
dnl
// vector mla
VMLA(B, B, 16)
VMLA(S, H, 8)
VMLA(I, S, 4)
VMLA(L, D, 2)

dnl
dnl VMLS($1           $2    $3         )
dnl VMLS(name_suffix, size, min_vec_len)
define(`VMLS', `
// dst_src1 = dst_src1 - src2 * src3
instruct vmls$1(vReg dst_src1, vReg src2, vReg src3)
%{
  predicate(UseSVE > 0 && n->as_Vector()->length() >= $3);
  match(Set dst_src1 (SubV$1 dst_src1 (MulV$1 src2 src3)));
  ins_cost(SVE_COST);
  format %{ "sve_mls $dst_src1, src2, src3\t # vector (sve) ($2)" %}
  ins_encode %{
    __ sve_mls(as_FloatRegister($dst_src1$$reg), __ $2,
      ptrue, as_FloatRegister($src2$$reg), as_FloatRegister($src3$$reg));
  %}
  ins_pipe(pipe_slow);
%}')dnl
dnl
// vector mls
VMLS(B, B, 16)
VMLS(S, H, 8)
VMLS(I, S, 4)
VMLS(L, D, 2)

dnl
dnl BINARY_OP_TRUE_PREDICATE($1,        $2,      $3,   $4,          $5  )
dnl BINARY_OP_TRUE_PREDICATE(insn_name, op_name, size, min_vec_len, insn)
define(`BINARY_OP_TRUE_PREDICATE', `
instruct $1(vReg dst_src1, vReg src2) %{
  predicate(UseSVE > 0 && n->as_Vector()->length() >= $4);
  match(Set dst_src1 ($2 dst_src1 src2));
  ins_cost(SVE_COST);
  format %{ "$5 $dst_src1, $dst_src1, $src2\t # vector (sve) ($3)" %}
  ins_encode %{
    __ $5(as_FloatRegister($dst_src1$$reg), __ $3,
         ptrue, as_FloatRegister($src2$$reg));
  %}
  ins_pipe(pipe_slow);
%}')dnl

// vector mul
BINARY_OP_TRUE_PREDICATE(vmulB, MulVB, B, 16, sve_mul)
BINARY_OP_TRUE_PREDICATE(vmulS, MulVS, H, 8,  sve_mul)
BINARY_OP_TRUE_PREDICATE(vmulI, MulVI, S, 4,  sve_mul)
BINARY_OP_TRUE_PREDICATE(vmulL, MulVL, D, 2,  sve_mul)
BINARY_OP_UNPREDICATED(vmulF, MulVF, S, 4, sve_fmul)
BINARY_OP_UNPREDICATED(vmulD, MulVD, D, 2, sve_fmul)

dnl
dnl UNARY_OP_TRUE_PREDICATE($1,        $2,      $3,   $4,            $5  )
dnl UNARY_OP_TRUE_PREDICATE(insn_name, op_name, size, min_vec_bytes, insn)
define(`UNARY_OP_TRUE_PREDICATE', `
instruct $1(vReg dst, vReg src) %{
  predicate(UseSVE > 0 && n->as_Vector()->length_in_bytes() >= $4);
  match(Set dst ($2 src));
  ins_cost(SVE_COST);
  format %{ "$5 $dst, $src\t# vector (sve) ($3)" %}
  ins_encode %{
    __ $5(as_FloatRegister($dst$$reg), __ $3,
         ptrue, as_FloatRegister($src$$reg));
  %}
  ins_pipe(pipe_slow);
%}')dnl
dnl
// vector fneg
UNARY_OP_TRUE_PREDICATE(vnegF, NegVF, S, 16, sve_fneg)
UNARY_OP_TRUE_PREDICATE(vnegD, NegVD, D, 16, sve_fneg)

// popcount vector

instruct vpopcountI(vReg dst, vReg src) %{
  predicate(UseSVE > 0 && n->as_Vector()->length() >= 4);
  match(Set dst (PopCountVI src));
  format %{ "sve_cnt $dst, $src\t# vector (sve) (S)\n\t"  %}
  ins_encode %{
     __ sve_cnt(as_FloatRegister($dst$$reg), __ S, ptrue, as_FloatRegister($src$$reg));
  %}
  ins_pipe(pipe_slow);
%}dnl

dnl
dnl REDUCE_ADD_EXT($1,        $2,      $3,      $4,      $5,   $6,        $7   )
dnl REDUCE_ADD_EXT(insn_name, op_name, reg_dst, reg_src, size, elem_type, insn1)
define(`REDUCE_ADD_EXT', `
instruct $1($3 dst, $4 src1, vReg src2, vRegD tmp) %{
  predicate(UseSVE > 0 && n->in(2)->bottom_type()->is_vect()->length_in_bytes() >= 16 &&
            n->in(2)->bottom_type()->is_vect()->element_basic_type() == $6);
  match(Set dst ($2 src1 src2));
  effect(TEMP_DEF dst, TEMP tmp);
  ins_cost(SVE_COST);
  format %{ "sve_uaddv $tmp, $src2\t# vector (sve) ($5)\n\t"
            "smov  $dst, $tmp, $5, 0\n\t"
            "addw  $dst, $dst, $src1\n\t"
            "$7  $dst, $dst\t # add reduction $5" %}
  ins_encode %{
    __ sve_uaddv(as_FloatRegister($tmp$$reg), __ $5,
         ptrue, as_FloatRegister($src2$$reg));
    __ smov($dst$$Register, as_FloatRegister($tmp$$reg), __ $5, 0);
    __ addw($dst$$Register, $dst$$Register, $src1$$Register);
    __ $7($dst$$Register, $dst$$Register);
  %}
  ins_pipe(pipe_slow);
%}')dnl
dnl
dnl REDUCE_ADD($1,        $2,      $3,      $4,      $5,   $6,        $7   )
dnl REDUCE_ADD(insn_name, op_name, reg_dst, reg_src, size, elem_type, insn1)
define(`REDUCE_ADD', `
instruct $1($3 dst, $4 src1, vReg src2, vRegD tmp) %{
  predicate(UseSVE > 0 && n->in(2)->bottom_type()->is_vect()->length_in_bytes() >= 16 &&
            n->in(2)->bottom_type()->is_vect()->element_basic_type() == $6);
  match(Set dst ($2 src1 src2));
  effect(TEMP_DEF dst, TEMP tmp);
  ins_cost(SVE_COST);
  format %{ "sve_uaddv $tmp, $src2\t# vector (sve) ($5)\n\t"
            "umov  $dst, $tmp, $5, 0\n\t"
            "$7  $dst, $dst, $src1\t # add reduction $5" %}
  ins_encode %{
    __ sve_uaddv(as_FloatRegister($tmp$$reg), __ $5,
         ptrue, as_FloatRegister($src2$$reg));
    __ umov($dst$$Register, as_FloatRegister($tmp$$reg), __ $5, 0);
    __ $7($dst$$Register, $dst$$Register, $src1$$Register);
  %}
  ins_pipe(pipe_slow);
%}')dnl
dnl
dnl REDUCE_ADDF($1,        $2,      $3,      $4  )
dnl REDUCE_ADDF(insn_name, op_name, reg_dst, size)
define(`REDUCE_ADDF', `
instruct $1($3 src1_dst, vReg src2) %{
  predicate(UseSVE > 0 && n->in(2)->bottom_type()->is_vect()->length_in_bytes() >= 16);
  match(Set src1_dst ($2 src1_dst src2));
  ins_cost(SVE_COST);
  format %{ "sve_fadda $src1_dst, $src1_dst, $src2\t# vector (sve) ($4)" %}
  ins_encode %{
    __ sve_fadda(as_FloatRegister($src1_dst$$reg), __ $4,
         ptrue, as_FloatRegister($src2$$reg));
  %}
  ins_pipe(pipe_slow);
%}')dnl

// vector add reduction
REDUCE_ADD_EXT(reduce_addB, AddReductionVI, iRegINoSp, iRegIorL2I, B, T_BYTE,  sxtb)
REDUCE_ADD_EXT(reduce_addS, AddReductionVI, iRegINoSp, iRegIorL2I, H, T_SHORT, sxth)
REDUCE_ADD(reduce_addI, AddReductionVI, iRegINoSp, iRegIorL2I, S, T_INT, addw)
REDUCE_ADD(reduce_addL, AddReductionVL, iRegLNoSp, iRegL, D, T_LONG, add)
REDUCE_ADDF(reduce_addF, AddReductionVF, vRegF, S)
REDUCE_ADDF(reduce_addD, AddReductionVD, vRegD, D)

dnl
dnl REDUCE_FMINMAX($1,      $2,          $3,           $4,   $5         )
dnl REDUCE_FMINMAX(min_max, name_suffix, element_type, size, reg_src_dst)
define(`REDUCE_FMINMAX', `
instruct reduce_$1$2($5 dst, $5 src1, vReg src2) %{
  predicate(UseSVE > 0 && n->in(2)->bottom_type()->is_vect()->element_basic_type() == $3 &&
            n->in(2)->bottom_type()->is_vect()->length_in_bytes() >= 16);
  match(Set dst (translit($1, `m', `M')ReductionV src1 src2));
  ins_cost(INSN_COST);
  effect(TEMP_DEF dst);
  format %{ "sve_f$1v $dst, $src2 # vector (sve) (S)\n\t"
            "f$1s $dst, $dst, $src1\t # $1 reduction $2" %}
  ins_encode %{
    __ sve_f$1v(as_FloatRegister($dst$$reg), __ $4,
         ptrue, as_FloatRegister($src2$$reg));
    __ f`$1'translit($4, `SD', `sd')(as_FloatRegister($dst$$reg), as_FloatRegister($dst$$reg), as_FloatRegister($src1$$reg));
  %}
  ins_pipe(pipe_slow);
%}')dnl
// vector max reduction
REDUCE_FMINMAX(max, F, T_FLOAT,  S, vRegF)
REDUCE_FMINMAX(max, D, T_DOUBLE, D, vRegD)

// vector min reduction
REDUCE_FMINMAX(min, F, T_FLOAT,  S, vRegF)
REDUCE_FMINMAX(min, D, T_DOUBLE, D, vRegD)

// vector Math.rint, floor, ceil

instruct vroundD(vReg dst, vReg src, immI rmode) %{
  predicate(UseSVE > 0 && n->as_Vector()->length() >= 2 &&
            n->bottom_type()->is_vect()->element_basic_type() == T_DOUBLE);
  match(Set dst (RoundDoubleModeV src rmode));
  format %{ "sve_frint $dst, $src, $rmode\t# vector (sve) (D)" %}
  ins_encode %{
    switch ($rmode$$constant) {
      case RoundDoubleModeNode::rmode_rint:
        __ sve_frintn(as_FloatRegister($dst$$reg), __ D,
             ptrue, as_FloatRegister($src$$reg));
        break;
      case RoundDoubleModeNode::rmode_floor:
        __ sve_frintm(as_FloatRegister($dst$$reg), __ D,
             ptrue, as_FloatRegister($src$$reg));
        break;
      case RoundDoubleModeNode::rmode_ceil:
        __ sve_frintp(as_FloatRegister($dst$$reg), __ D,
             ptrue, as_FloatRegister($src$$reg));
        break;
    }
  %}
  ins_pipe(pipe_slow);
%}
dnl
dnl REPLICATE($1,        $2,      $3,      $4,   $5         )
dnl REPLICATE(insn_name, op_name, reg_src, size, min_vec_len)
define(`REPLICATE', `
instruct $1(vReg dst, $3 src) %{
  predicate(UseSVE > 0 && n->as_Vector()->length() >= $5);
  match(Set dst ($2 src));
  ins_cost(SVE_COST);
  format %{ "sve_dup  $dst, $src\t# vector (sve) ($4)" %}
  ins_encode %{
    __ sve_dup(as_FloatRegister($dst$$reg), __ $4, as_Register($src$$reg));
  %}
  ins_pipe(pipe_slow);
%}')dnl
dnl
dnl REPLICATE_IMM8($1,        $2,      $3,       $4,   $5         )
dnl REPLICATE_IMM8(insn_name, op_name, imm_type, size, min_vec_len)
define(`REPLICATE_IMM8', `
instruct $1(vReg dst, $3 con) %{
  predicate(UseSVE > 0 && n->as_Vector()->length() >= $5);
  match(Set dst ($2 con));
  ins_cost(SVE_COST);
  format %{ "sve_dup  $dst, $con\t# vector (sve) ($4)" %}
  ins_encode %{
    __ sve_dup(as_FloatRegister($dst$$reg), __ $4, $con$$constant);
  %}
  ins_pipe(pipe_slow);
%}')dnl
dnl
dnl FREPLICATE($1,        $2,      $3,      $4,   $5         )
dnl FREPLICATE(insn_name, op_name, reg_src, size, min_vec_len)
define(`FREPLICATE', `
instruct $1(vReg dst, $3 src) %{
  predicate(UseSVE > 0 && n->as_Vector()->length() >= $5);
  match(Set dst ($2 src));
  ins_cost(SVE_COST);
  format %{ "sve_cpy  $dst, $src\t# vector (sve) ($4)" %}
  ins_encode %{
    __ sve_cpy(as_FloatRegister($dst$$reg), __ $4,
         ptrue, as_FloatRegister($src$$reg));
  %}
  ins_pipe(pipe_slow);
%}')dnl

// vector replicate
REPLICATE(replicateB, ReplicateB, iRegIorL2I, B, 16)
REPLICATE(replicateS, ReplicateS, iRegIorL2I, H, 8)
REPLICATE(replicateI, ReplicateI, iRegIorL2I, S, 4)
REPLICATE(replicateL, ReplicateL, iRegL,      D, 2)
REPLICATE_IMM8(replicateB_imm8, ReplicateB, immI8,        B, 16)
REPLICATE_IMM8(replicateS_imm8, ReplicateS, immI8_shift8, H, 8)
REPLICATE_IMM8(replicateI_imm8, ReplicateI, immI8_shift8, S, 4)
REPLICATE_IMM8(replicateL_imm8, ReplicateL, immL8_shift8, D, 2)
FREPLICATE(replicateF, ReplicateF, vRegF, S, 4)
FREPLICATE(replicateD, ReplicateD, vRegD, D, 2)
dnl
dnl VSHIFT_TRUE_PREDICATE($1,        $2,      $3,   $4,          $5  )
dnl VSHIFT_TRUE_PREDICATE(insn_name, op_name, size, min_vec_len, insn)
define(`VSHIFT_TRUE_PREDICATE', `
instruct $1(vReg dst, vReg shift) %{
  predicate(UseSVE > 0 && n->as_Vector()->length() >= $4);
  match(Set dst ($2 dst shift));
  ins_cost(SVE_COST);
  format %{ "$5 $dst, $dst, $shift\t# vector (sve) ($3)" %}
  ins_encode %{
    __ $5(as_FloatRegister($dst$$reg), __ $3,
         ptrue, as_FloatRegister($shift$$reg));
  %}
  ins_pipe(pipe_slow);
%}')dnl
dnl
dnl VSHIFT_IMM_UNPREDICATED($1,        $2,      $3,       $4,   $5,          $6  )
dnl VSHIFT_IMM_UNPREDICATED(insn_name, op_name, op_name2, size, min_vec_len, insn)
define(`VSHIFT_IMM_UNPREDICATED', `
instruct $1(vReg dst, vReg src, immI shift) %{
  predicate(UseSVE > 0 && n->as_Vector()->length() >= $5);
  match(Set dst ($2 src ($3 shift)));
  ins_cost(SVE_COST);
  format %{ "$6 $dst, $src, $shift\t# vector (sve) ($4)" %}
  ins_encode %{
    int con = (int)$shift$$constant;dnl
ifelse(eval(index(`$1', `vasr') == 0 || index(`$1', `vlsr') == 0), 1, `
    if (con == 0) {
      __ sve_orr(as_FloatRegister($dst$$reg), as_FloatRegister($src$$reg),
           as_FloatRegister($src$$reg));
      return;
    }')dnl
ifelse(eval(index(`$1', `vasr') == 0), 1, `ifelse(eval(index(`$4', `B') == 0), 1, `
    if (con >= 8) con = 7;')ifelse(eval(index(`$4', `H') == 0), 1, `
    if (con >= 16) con = 15;')')dnl
ifelse(eval(index(`$1', `vlsl') == 0  || index(`$1', `vlsr') == 0), 1, `ifelse(eval(index(`$4', `B') == 0), 1, `
    if (con >= 8) {
      __ sve_eor(as_FloatRegister($dst$$reg), as_FloatRegister($src$$reg),
           as_FloatRegister($src$$reg));
      return;
    }')ifelse(eval(index(`$4', `H') == 0), 1, `
    if (con >= 16) {
      __ sve_eor(as_FloatRegister($dst$$reg), as_FloatRegister($src$$reg),
           as_FloatRegister($src$$reg));
      return;
    }')')
    __ $6(as_FloatRegister($dst$$reg), __ $4,
         as_FloatRegister($src$$reg), con);
  %}
  ins_pipe(pipe_slow);
%}')dnl
dnl
dnl VSHIFT_COUNT($1,        $2,   $3,          $4  )
dnl VSHIFT_COUNT(insn_name, size, min_vec_len, type)
define(`VSHIFT_COUNT', `
instruct $1(vReg dst, iRegIorL2I cnt) %{
  predicate(UseSVE > 0 && n->as_Vector()->length() >= $3 &&
            ELEMENT_SHORT_CHAR($4, n));
  match(Set dst (LShiftCntV cnt));
  match(Set dst (RShiftCntV cnt));
  format %{ "sve_dup $dst, $cnt\t# vector shift count (sve) ($2)" %}
  ins_encode %{
    __ sve_dup(as_FloatRegister($dst$$reg), __ $2, as_Register($cnt$$reg));
  %}
  ins_pipe(pipe_slow);
%}')dnl

// vector shift
VSHIFT_TRUE_PREDICATE(vasrB, RShiftVB,  B, 16, sve_asr)
VSHIFT_TRUE_PREDICATE(vasrS, RShiftVS,  H,  8, sve_asr)
VSHIFT_TRUE_PREDICATE(vasrI, RShiftVI,  S,  4, sve_asr)
VSHIFT_TRUE_PREDICATE(vasrL, RShiftVL,  D,  2, sve_asr)
VSHIFT_TRUE_PREDICATE(vlslB, LShiftVB,  B, 16, sve_lsl)
VSHIFT_TRUE_PREDICATE(vlslS, LShiftVS,  H,  8, sve_lsl)
VSHIFT_TRUE_PREDICATE(vlslI, LShiftVI,  S,  4, sve_lsl)
VSHIFT_TRUE_PREDICATE(vlslL, LShiftVL,  D,  2, sve_lsl)
VSHIFT_TRUE_PREDICATE(vlsrB, URShiftVB, B, 16, sve_lsr)
VSHIFT_TRUE_PREDICATE(vlsrS, URShiftVS, H,  8, sve_lsr)
VSHIFT_TRUE_PREDICATE(vlsrI, URShiftVI, S,  4, sve_lsr)
VSHIFT_TRUE_PREDICATE(vlsrL, URShiftVL, D,  2, sve_lsr)
VSHIFT_IMM_UNPREDICATED(vasrB_imm, RShiftVB,  RShiftCntV, B, 16, sve_asr)
VSHIFT_IMM_UNPREDICATED(vasrS_imm, RShiftVS,  RShiftCntV, H,  8, sve_asr)
VSHIFT_IMM_UNPREDICATED(vasrI_imm, RShiftVI,  RShiftCntV, S,  4, sve_asr)
VSHIFT_IMM_UNPREDICATED(vasrL_imm, RShiftVL,  RShiftCntV, D,  2, sve_asr)
VSHIFT_IMM_UNPREDICATED(vlsrB_imm, URShiftVB, RShiftCntV, B, 16, sve_lsr)
VSHIFT_IMM_UNPREDICATED(vlsrS_imm, URShiftVS, RShiftCntV, H,  8, sve_lsr)
VSHIFT_IMM_UNPREDICATED(vlsrI_imm, URShiftVI, RShiftCntV, S,  4, sve_lsr)
VSHIFT_IMM_UNPREDICATED(vlsrL_imm, URShiftVL, RShiftCntV, D,  2, sve_lsr)
VSHIFT_IMM_UNPREDICATED(vlslB_imm, LShiftVB,  LShiftCntV, B, 16, sve_lsl)
VSHIFT_IMM_UNPREDICATED(vlslS_imm, LShiftVS,  LShiftCntV, H,  8, sve_lsl)
VSHIFT_IMM_UNPREDICATED(vlslI_imm, LShiftVI,  LShiftCntV, S,  4, sve_lsl)
VSHIFT_IMM_UNPREDICATED(vlslL_imm, LShiftVL,  LShiftCntV, D,  2, sve_lsl)
VSHIFT_COUNT(vshiftcntB, B, 16, T_BYTE)
VSHIFT_COUNT(vshiftcntS, H,  8, T_SHORT)
VSHIFT_COUNT(vshiftcntI, S,  4, T_INT)
VSHIFT_COUNT(vshiftcntL, D,  2, T_LONG)

// vector sqrt
UNARY_OP_TRUE_PREDICATE(vsqrtF, SqrtVF, S, 16, sve_fsqrt)
UNARY_OP_TRUE_PREDICATE(vsqrtD, SqrtVD, D, 16, sve_fsqrt)

// vector sub
BINARY_OP_UNPREDICATED(vsubB, SubVB, B, 16, sve_sub)
BINARY_OP_UNPREDICATED(vsubS, SubVS, H, 8, sve_sub)
BINARY_OP_UNPREDICATED(vsubI, SubVI, S, 4, sve_sub)
BINARY_OP_UNPREDICATED(vsubL, SubVL, D, 2, sve_sub)
BINARY_OP_UNPREDICATED(vsubF, SubVF, S, 4, sve_fsub)
BINARY_OP_UNPREDICATED(vsubD, SubVD, D, 2, sve_fsub)

// vector mask cast

instruct vmaskcast(vReg dst) %{
  predicate(UseSVE > 0 && n->bottom_type()->is_vect()->length() == n->in(1)->bottom_type()->is_vect()->length() &&
            n->bottom_type()->is_vect()->length_in_bytes() == n->in(1)->bottom_type()->is_vect()->length_in_bytes());
  match(Set dst (VectorMaskCast dst));
  ins_cost(0);
  format %{ "vmaskcast $dst\t# empty (sve)" %}
  ins_encode %{
    // empty
  %}
  ins_pipe(pipe_class_empty);
%}

instruct string_indexof_char_sve(iRegP_R1 str1, iRegI_R2 cnt1, iRegI_R3 ch,
                                 iRegI_R0 result, vReg ztmp1, vReg ztmp2,
                                 pRegGov pgtmp, pReg ptmp, rFlagsReg cr)
%{
  match(Set result (StrIndexOfChar (Binary str1 cnt1) ch));
  predicate((UseSVE > 0) && (((StrIndexOfCharNode*)n)->encoding() == StrIntrinsicNode::U));
  effect(TEMP ztmp1, TEMP ztmp2, TEMP pgtmp, TEMP ptmp, KILL cr);

  format %{ "StringUTF16 IndexOf char[] $str1,$cnt1,$ch -> $result # use sve" %}

  ins_encode %{
    __ string_indexof_char_sve($str1$$Register, $cnt1$$Register, $ch$$Register, $result$$Register,
                               as_FloatRegister($ztmp1$$reg), as_FloatRegister($ztmp2$$reg),
                               as_PRegister($pgtmp$$reg), as_PRegister($ptmp$$reg), false /* isL */);
  %}
  ins_pipe(pipe_class_memory);
%}

instruct stringL_indexof_char_sve(iRegP_R1 str1, iRegI_R2 cnt1, iRegI_R3 ch,
                                  iRegI_R0 result, vReg ztmp1, vReg ztmp2,
                                  pRegGov pgtmp, pReg ptmp, rFlagsReg cr)
%{
  match(Set result (StrIndexOfChar (Binary str1 cnt1) ch));
  predicate((UseSVE > 0) && (((StrIndexOfCharNode*)n)->encoding() == StrIntrinsicNode::L));
  effect(TEMP ztmp1, TEMP ztmp2, TEMP pgtmp, TEMP ptmp, KILL cr);

  format %{ "StringLatin1 IndexOf char[] $str1,$cnt1,$ch -> $result # use sve" %}

  ins_encode %{
    __ string_indexof_char_sve($str1$$Register, $cnt1$$Register, $ch$$Register, $result$$Register,
                               as_FloatRegister($ztmp1$$reg), as_FloatRegister($ztmp2$$reg),
                               as_PRegister($pgtmp$$reg), as_PRegister($ptmp$$reg), true /* isL */);
  %}
  ins_pipe(pipe_class_memory);
%}

