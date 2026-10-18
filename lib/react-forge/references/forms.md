# React Forms

## Contents

- [Core Workflow](#core-workflow)
- [Key Gotchas](#key-gotchas)
- [Quick Reference](#quick-reference)
- [Controlled Forms](#controlled-forms)
- [React Hook Form](#react-hook-form)
- [Server Actions with Forms](#server-actions-with-forms) (moved to [forms-server-actions.md](forms-server-actions.md))
- [Custom Form Components](#custom-form-components)
- [File Upload Forms](#file-upload-forms) (moved to [forms-advanced.md](forms-advanced.md#file-upload-forms))
- [Multi-Step Forms](#multi-step-forms) (moved to [forms-advanced.md](forms-advanced.md#multi-step-forms))
- [Best Practices](#best-practices)

## Core Workflow

1. Choose the form model: controlled state for simple forms, React Hook Form for complex client forms, or Server Actions for framework-native submissions (see [forms-server-actions.md](forms-server-actions.md)).
2. Define validation near the data contract; prefer schema validation such as Zod when the shape is shared or complex.
3. Wire accessibility from the start with labels, `aria-invalid`, `aria-describedby`, error text near fields, and disabled/loading submit states.
4. For dynamic fields, use stable field IDs from `useFieldArray` and preserve validation paths as items are added, removed, or moved.
5. For file uploads, validate type/size, generate previews only when appropriate, and submit via `FormData` (see [forms-advanced.md](forms-advanced.md#file-upload-forms)).
6. For multi-step forms, validate only the current step before advancing and keep one form context across steps when data must persist (see [forms-advanced.md](forms-advanced.md#multi-step-forms)).

## Key Gotchas

- Do not mix controlled and uncontrolled patterns on the same input without a deliberate bridge component.
- Disable submit while pending to prevent duplicate submissions.
- Always surface server-side validation errors, even when client validation exists.
- File previews can leak memory if object URLs are not revoked; Data URLs can be large for big files.
- In Server Actions, keep progressive enhancement and pending/error states visible to the user.

## Quick Reference

| Approach | Best For | Example |
|----------|----------|---------|
| Controlled | Simple forms | `value={state} onChange={...}` |
| React Hook Form | Complex forms | `useForm()` + `register()` |
| Server Actions | Framework-native forms (in a framework that supports them); see [forms-server-actions.md](forms-server-actions.md) | `useActionState(action, initialState)` |

| React Hook Form | Usage |
|-----------------|-------|
| `register` | Connect input | `{...register('name')}` |
| `handleSubmit` | Form submission | `onSubmit={handleSubmit(fn)}` |
| `formState.errors` | Validation errors | `errors.name?.message` |
| `useFieldArray` | Dynamic fields | `fields.map(...)` |

| Validation | Setup |
|------------|-------|
| Inline | `register('email', { required: true })` |
| Zod | `resolver: zodResolver(schema)` |

## Controlled Forms

### Basic Controlled Form

```tsx
'use client';

import { useState, FormEvent, ChangeEvent } from 'react';

interface ContactValues {
  name: string;
  email: string;
  message: string;
}

function ContactForm() {
  const [formData, setFormData] = useState<ContactValues>({
    name: '',
    email: '',
    message: '',
  });

  const handleChange = (
    e: ChangeEvent<HTMLInputElement | HTMLTextAreaElement>
  ) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
  };

  const handleSubmit = (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    console.log('Form submitted:', formData);
  };

  return (
    <form onSubmit={handleSubmit}>
      <div>
        <label htmlFor="name">Name</label>
        <input
          id="name"
          name="name"
          type="text"
          value={formData.name}
          onChange={handleChange}
          required
        />
      </div>
      <div>
        <label htmlFor="email">Email</label>
        <input
          id="email"
          name="email"
          type="email"
          value={formData.email}
          onChange={handleChange}
          required
        />
      </div>
      <div>
        <label htmlFor="message">Message</label>
        <textarea
          id="message"
          name="message"
          value={formData.message}
          onChange={handleChange}
          required
        />
      </div>
      <button type="submit">Send</button>
    </form>
  );
}
```

### Form with Validation

```tsx
'use client';

import { useState, FormEvent, ChangeEvent } from 'react';

interface SignupValues {
  email: string;
  password: string;
  confirmPassword: string;
}

interface FormErrors {
  email?: string;
  password?: string;
  confirmPassword?: string;
}

function SignupForm() {
  const [formData, setFormData] = useState<SignupValues>({
    email: '',
    password: '',
    confirmPassword: '',
  });
  const [errors, setErrors] = useState<FormErrors>({});
  const [touched, setTouched] = useState<Record<string, boolean>>({});

  const validate = (data: SignupValues): FormErrors => {
    const errors: FormErrors = {};

    if (!data.email) {
      errors.email = 'Email is required';
    } else if (!/^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i.test(data.email)) {
      errors.email = 'Invalid email address';
    }

    if (!data.password) {
      errors.password = 'Password is required';
    } else if (data.password.length < 8) {
      errors.password = 'Password must be at least 8 characters';
    }

    if (data.password !== data.confirmPassword) {
      errors.confirmPassword = 'Passwords do not match';
    }

    return errors;
  };

  const handleChange = (e: ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    const newFormData = { ...formData, [name]: value };
    setFormData(newFormData);

    // Validate on change if field was touched
    if (touched[name]) {
      setErrors(validate(newFormData));
    }
  };

  const handleBlur = (e: ChangeEvent<HTMLInputElement>) => {
    const { name } = e.target;
    setTouched((prev) => ({ ...prev, [name]: true }));
    setErrors(validate(formData));
  };

  const handleSubmit = (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const validationErrors = validate(formData);
    setErrors(validationErrors);
    setTouched({ email: true, password: true, confirmPassword: true });

    if (Object.keys(validationErrors).length === 0) {
      console.log('Form is valid:', formData);
    }
  };

  return (
    <form onSubmit={handleSubmit} noValidate>
      <div>
        <label htmlFor="email">Email</label>
        <input
          id="email"
          name="email"
          type="email"
          value={formData.email}
          onChange={handleChange}
          onBlur={handleBlur}
          aria-invalid={!!errors.email}
          aria-describedby={errors.email ? 'email-error' : undefined}
        />
        {touched.email && errors.email && (
          <span id="email-error" className="error">{errors.email}</span>
        )}
      </div>

      <div>
        <label htmlFor="password">Password</label>
        <input
          id="password"
          name="password"
          type="password"
          value={formData.password}
          onChange={handleChange}
          onBlur={handleBlur}
          aria-invalid={!!errors.password}
          aria-describedby={errors.password ? 'password-error' : undefined}
        />
        {touched.password && errors.password && (
          <span id="password-error" className="error">{errors.password}</span>
        )}
      </div>

      <div>
        <label htmlFor="confirmPassword">Confirm Password</label>
        <input
          id="confirmPassword"
          name="confirmPassword"
          type="password"
          value={formData.confirmPassword}
          onChange={handleChange}
          onBlur={handleBlur}
          aria-invalid={!!errors.confirmPassword}
          aria-describedby={errors.confirmPassword ? 'confirmPassword-error' : undefined}
        />
        {touched.confirmPassword && errors.confirmPassword && (
          <span id="confirmPassword-error" className="error">{errors.confirmPassword}</span>
        )}
      </div>

      <button type="submit">Sign Up</button>
    </form>
  );
}
```

## React Hook Form

### Basic Setup

```tsx
'use client';

import { useForm, SubmitHandler } from 'react-hook-form';

interface FormInputs {
  firstName: string;
  lastName: string;
  email: string;
  age: number;
}

function BasicForm() {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<FormInputs>();

  const onSubmit: SubmitHandler<FormInputs> = async (data) => {
    await new Promise((resolve) => setTimeout(resolve, 1000));
    console.log(data);
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} noValidate>
      <div>
        <label htmlFor="firstName">First Name</label>
        <input
          id="firstName"
          aria-invalid={!!errors.firstName}
          aria-describedby={errors.firstName ? 'firstName-error' : undefined}
          {...register('firstName', { required: 'First name is required' })}
        />
        {errors.firstName && <span id="firstName-error">{errors.firstName.message}</span>}
      </div>

      <div>
        <label htmlFor="lastName">Last Name</label>
        <input
          id="lastName"
          aria-invalid={!!errors.lastName}
          aria-describedby={errors.lastName ? 'lastName-error' : undefined}
          {...register('lastName', { required: 'Last name is required' })}
        />
        {errors.lastName && <span id="lastName-error">{errors.lastName.message}</span>}
      </div>

      <div>
        <label htmlFor="email">Email</label>
        <input
          id="email"
          type="email"
          aria-invalid={!!errors.email}
          aria-describedby={errors.email ? 'email-error' : undefined}
          {...register('email', {
            required: 'Email is required',
            pattern: {
              value: /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i,
              message: 'Invalid email address',
            },
          })}
        />
        {errors.email && <span id="email-error">{errors.email.message}</span>}
      </div>

      <div>
        <label htmlFor="age">Age</label>
        <input
          id="age"
          type="number"
          aria-invalid={!!errors.age}
          aria-describedby={errors.age ? 'age-error' : undefined}
          {...register('age', {
            valueAsNumber: true,
            required: 'Age is required',
            min: { value: 18, message: 'Must be at least 18' },
            max: { value: 120, message: 'Invalid age' },
          })}
        />
        {errors.age && <span id="age-error">{errors.age.message}</span>}
      </div>

      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Submitting...' : 'Submit'}
      </button>
    </form>
  );
}
```

### With Zod Validation

```tsx
'use client';

import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';

// Zod 4 syntax: top-level string formats and the unified `error` param
const schema = z.object({
  username: z
    .string()
    .min(3, 'Username must be at least 3 characters')
    .max(20, 'Username must be less than 20 characters')
    .regex(/^[a-z0-9_]+$/, 'Only lowercase letters, numbers, and underscores'),
  email: z.email('Invalid email address'),
  password: z
    .string()
    .min(8, 'Password must be at least 8 characters')
    .regex(/[A-Z]/, 'Must contain at least one uppercase letter')
    .regex(/[0-9]/, 'Must contain at least one number'),
  confirmPassword: z.string(),
  role: z.enum(['user', 'admin', 'moderator']),
  terms: z.literal(true, { error: 'You must accept the terms' }),
}).refine((data) => data.password === data.confirmPassword, {
  error: 'Passwords do not match',
  path: ['confirmPassword'],
});

type SignupInput = z.infer<typeof schema>;

function ZodForm() {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
    reset,
  } = useForm<SignupInput>({
    resolver: zodResolver(schema),
    defaultValues: {
      role: 'user',
    },
  });

  const onSubmit = async (data: SignupInput) => {
    await new Promise((resolve) => setTimeout(resolve, 1000));
    console.log(data);
    reset();
  };

  // Helper for the repeated a11y wiring
  const a11y = (name: keyof SignupInput) => ({
    id: name,
    'aria-invalid': !!errors[name],
    'aria-describedby': errors[name] ? `${name}-error` : undefined,
  });

  return (
    <form onSubmit={handleSubmit(onSubmit)} noValidate>
      <div>
        <label htmlFor="username">Username</label>
        <input {...a11y('username')} {...register('username')} />
        {errors.username && <span id="username-error">{errors.username.message}</span>}
      </div>

      <div>
        <label htmlFor="email">Email</label>
        <input type="email" {...a11y('email')} {...register('email')} />
        {errors.email && <span id="email-error">{errors.email.message}</span>}
      </div>

      <div>
        <label htmlFor="password">Password</label>
        <input type="password" {...a11y('password')} {...register('password')} />
        {errors.password && <span id="password-error">{errors.password.message}</span>}
      </div>

      <div>
        <label htmlFor="confirmPassword">Confirm Password</label>
        <input type="password" {...a11y('confirmPassword')} {...register('confirmPassword')} />
        {errors.confirmPassword && (
          <span id="confirmPassword-error">{errors.confirmPassword.message}</span>
        )}
      </div>

      <div>
        <label htmlFor="role">Role</label>
        <select {...a11y('role')} {...register('role')}>
          <option value="user">User</option>
          <option value="admin">Admin</option>
          <option value="moderator">Moderator</option>
        </select>
        {errors.role && <span id="role-error">{errors.role.message}</span>}
      </div>

      <div>
        <label>
          <input type="checkbox" {...a11y('terms')} {...register('terms')} />
          I accept the terms and conditions
        </label>
        {errors.terms && <span id="terms-error">{errors.terms.message}</span>}
      </div>

      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Submitting...' : 'Submit'}
      </button>
    </form>
  );
}
```

### Dynamic Fields with useFieldArray

```tsx
'use client';

import { useForm, useFieldArray, SubmitHandler } from 'react-hook-form';

interface FormValues {
  teamName: string;
  members: {
    name: string;
    email: string;
    role: string;
  }[];
}

function DynamicFieldsForm() {
  const {
    register,
    control,
    handleSubmit,
    formState: { errors },
  } = useForm<FormValues>({
    defaultValues: {
      teamName: '',
      members: [{ name: '', email: '', role: '' }],
    },
  });

  const { fields, append, remove, move } = useFieldArray({
    control,
    name: 'members',
  });

  const onSubmit: SubmitHandler<FormValues> = (data) => {
    console.log(data);
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} noValidate>
      <div>
        <label htmlFor="teamName">Team Name</label>
        <input
          id="teamName"
          aria-invalid={!!errors.teamName}
          aria-describedby={errors.teamName ? 'teamName-error' : undefined}
          {...register('teamName', { required: 'Team name is required' })}
        />
        {errors.teamName && <span id="teamName-error">{errors.teamName.message}</span>}
      </div>

      <h3>Team Members</h3>
      {fields.map((field, index) => {
        // field.id is stable across add/remove/move, so it is safe for DOM ids
        const nameId = `member-${field.id}-name`;
        const emailId = `member-${field.id}-email`;
        const roleId = `member-${field.id}-role`;
        const nameError = errors.members?.[index]?.name;

        return (
          <fieldset key={field.id} className="member-row">
            <legend>Member {index + 1}</legend>

            <label htmlFor={nameId}>Name</label>
            <input
              id={nameId}
              aria-invalid={!!nameError}
              aria-describedby={nameError ? `${nameId}-error` : undefined}
              {...register(`members.${index}.name` as const, {
                required: 'Name is required',
              })}
            />
            {nameError && <span id={`${nameId}-error`}>{nameError.message}</span>}

            <label htmlFor={emailId}>Email</label>
            <input
              id={emailId}
              type="email"
              {...register(`members.${index}.email` as const, {
                required: 'Email is required',
              })}
            />

            <label htmlFor={roleId}>Role</label>
            <select id={roleId} {...register(`members.${index}.role` as const)}>
              <option value="">Select role</option>
              <option value="developer">Developer</option>
              <option value="designer">Designer</option>
              <option value="manager">Manager</option>
            </select>

            <button type="button" onClick={() => remove(index)}>
              Remove
            </button>
            {index > 0 && (
              <button type="button" onClick={() => move(index, index - 1)}>
                Move Up
              </button>
            )}
          </fieldset>
        );
      })}

      <button
        type="button"
        onClick={() => append({ name: '', email: '', role: '' })}
      >
        Add Member
      </button>

      <button type="submit">Submit Team</button>
    </form>
  );
}
```

### Form with Watch and Conditional Fields

```tsx
'use client';

import { useForm, useWatch } from 'react-hook-form';

interface AccountValues {
  accountType: 'personal' | 'business';
  name: string;
  companyName?: string;
  taxId?: string;
  employeeCount?: string;
}

function ConditionalForm() {
  const { register, handleSubmit, control, formState: { errors } } = useForm<AccountValues>({
    defaultValues: {
      accountType: 'personal',
    },
    // Drop values of fields that unmount (business fields when switching back to personal)
    shouldUnregister: true,
  });

  const accountType = useWatch({
    control,
    name: 'accountType',
  });

  const onSubmit = (data: AccountValues) => {
    console.log(data);
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} noValidate>
      <div>
        <label htmlFor="accountType">Account Type</label>
        <select id="accountType" {...register('accountType')}>
          <option value="personal">Personal</option>
          <option value="business">Business</option>
        </select>
      </div>

      <div>
        <label htmlFor="name">Name</label>
        <input
          id="name"
          aria-invalid={!!errors.name}
          aria-describedby={errors.name ? 'name-error' : undefined}
          {...register('name', { required: 'Name is required' })}
        />
        {errors.name && <span id="name-error">{errors.name.message}</span>}
      </div>

      {accountType === 'business' && (
        <>
          <div>
            <label htmlFor="companyName">Company Name</label>
            <input
              id="companyName"
              aria-invalid={!!errors.companyName}
              aria-describedby={errors.companyName ? 'companyName-error' : undefined}
              {...register('companyName', { required: 'Company name is required' })}
            />
            {errors.companyName && (
              <span id="companyName-error">{errors.companyName.message}</span>
            )}
          </div>

          <div>
            <label htmlFor="taxId">Tax ID</label>
            <input
              id="taxId"
              aria-invalid={!!errors.taxId}
              aria-describedby={errors.taxId ? 'taxId-error' : 'taxId-hint'}
              {...register('taxId', {
                required: 'Tax ID is required',
                pattern: {
                  value: /^\d{2}-\d{7}$/,
                  message: 'Format: XX-XXXXXXX',
                },
              })}
            />
            <span id="taxId-hint">Format: XX-XXXXXXX</span>
            {errors.taxId && <span id="taxId-error">{errors.taxId.message}</span>}
          </div>

          <div>
            <label htmlFor="employeeCount">Number of Employees</label>
            <select id="employeeCount" {...register('employeeCount')}>
              <option value="1-10">1-10</option>
              <option value="11-50">11-50</option>
              <option value="51-200">51-200</option>
              <option value="200+">200+</option>
            </select>
          </div>
        </>
      )}

      <button type="submit">Submit</button>
    </form>
  );
}
```

## Server Actions with Forms

Moved to [forms-server-actions.md](forms-server-actions.md): `useActionState`, `bind` arguments, idempotent actions, `useOptimistic`, and `useFormStatus`.

## Custom Form Components

In React 19, `ref` is a regular prop on function components, so wrappers do not need `forwardRef`. Spreading `register('field')` passes `name`, `onChange`, `onBlur`, and `ref` straight through. (`forwardRef` is only needed as a React 18 fallback.)

### Reusable Input Component

```tsx
import { useId, type ComponentProps } from 'react';
import type { FieldError } from 'react-hook-form';

type InputProps = ComponentProps<'input'> & {
  label: string;
  error?: FieldError;
};

function Input({ label, error, id, className, ref, ...props }: InputProps) {
  const generatedId = useId();
  const inputId = id ?? generatedId;
  const errorId = `${inputId}-error`;

  return (
    <div className="form-field">
      <label htmlFor={inputId}>{label}</label>
      <input
        ref={ref}
        id={inputId}
        className={`input ${error ? 'input-error' : ''} ${className ?? ''}`}
        aria-invalid={!!error}
        aria-describedby={error ? errorId : undefined}
        {...props}
      />
      {error && (
        <span id={errorId} className="error-message">
          {error.message}
        </span>
      )}
    </div>
  );
}

export { Input };

// Usage with React Hook Form:
// <Input label="Email" type="email" error={errors.email} {...register('email')} />
```

### Select Component

```tsx
import { useId, type ComponentProps } from 'react';
import type { FieldError } from 'react-hook-form';

interface Option {
  value: string;
  label: string;
}

type SelectProps = ComponentProps<'select'> & {
  label: string;
  options: Option[];
  error?: FieldError;
  placeholder?: string;
};

function Select({ label, options, error, placeholder, id, ref, ...props }: SelectProps) {
  const generatedId = useId();
  const selectId = id ?? generatedId;
  const errorId = `${selectId}-error`;

  return (
    <div className="form-field">
      <label htmlFor={selectId}>{label}</label>
      <select
        ref={ref}
        id={selectId}
        className={`select ${error ? 'select-error' : ''}`}
        aria-invalid={!!error}
        aria-describedby={error ? errorId : undefined}
        {...props}
      >
        {placeholder && (
          <option value="" disabled>
            {placeholder}
          </option>
        )}
        {options.map((option) => (
          <option key={option.value} value={option.value}>
            {option.label}
          </option>
        ))}
      </select>
      {error && (
        <span id={errorId} className="error-message">
          {error.message}
        </span>
      )}
    </div>
  );
}

export { Select };

// Usage: <Select label="Role" options={roles} error={errors.role} {...register('role')} />
```

### Checkbox Group

```tsx
import { useId } from 'react';
import type { FieldError, FieldValues, Path, RegisterOptions, UseFormRegister } from 'react-hook-form';

interface CheckboxOption {
  value: string;
  label: string;
}

interface CheckboxGroupProps<T extends FieldValues> {
  name: Path<T>;
  label: string;
  options: CheckboxOption[];
  error?: FieldError;
  register: UseFormRegister<T>;
  validation?: RegisterOptions<T, Path<T>>;
}

function CheckboxGroup<T extends FieldValues>({
  name,
  label,
  options,
  error,
  register,
  validation,
}: CheckboxGroupProps<T>) {
  const errorId = `${useId()}-error`;

  return (
    <fieldset className="form-field" aria-describedby={error ? errorId : undefined}>
      <legend>{label}</legend>
      <div className="checkbox-group">
        {options.map((option) => (
          <label key={option.value} className="checkbox-label">
            <input
              type="checkbox"
              value={option.value}
              aria-invalid={!!error}
              {...register(name, validation)}
            />
            {option.label}
          </label>
        ))}
      </div>
      {error && (
        <span id={errorId} className="error-message">
          {error.message}
        </span>
      )}
    </fieldset>
  );
}

export { CheckboxGroup };
```

## File Upload Forms

Moved to [forms-advanced.md](forms-advanced.md#file-upload-forms): single-file upload with validation and preview, and accessible drag and drop.

## Multi-Step Forms

Moved to [forms-advanced.md](forms-advanced.md#multi-step-forms): wizard with per-step validation using one React Hook Form context.

## Best Practices

| Practice | Description |
|----------|-------------|
| Use uncontrolled inputs by default | With React Hook Form or native form actions (`<form action>`), let the DOM hold values; switch to controlled inputs when the UI needs the value on every keystroke (live previews, dependent fields, input masking) |
| Validate on blur | Balance between UX and validation feedback |
| Show errors near inputs | Improves form accessibility |
| Disable submit while loading | Prevents duplicate submissions; for retry-safe writes see [Idempotent Server Actions](forms-server-actions.md#idempotent-server-actions) |
| Use proper input types | `email`, `tel`, `number` for better UX |
| Add aria attributes | `aria-invalid`, `aria-describedby` |
| Clear form on success | Reset state after successful submission |
| Handle server errors | Display API validation errors; Server Action error state is in [forms-server-actions.md](forms-server-actions.md#basic-server-action-form) |
