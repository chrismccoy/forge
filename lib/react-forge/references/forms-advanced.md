# React Forms: File Uploads and Multi-Step Forms

Load this when building file upload inputs (single file, drag and drop) or multi-step wizard forms with per-step validation.

**Prerequisites:** the multi-step example uses React Hook Form (`useForm`, `FormProvider`, `trigger`); see [forms.md](forms.md#react-hook-form) for setup and [forms.md](forms.md#custom-form-components) for reusable field components. To submit through a Server Action instead of `fetch`, see [forms-server-actions.md](forms-server-actions.md).

## Contents

- [File Upload Forms](#file-upload-forms)
  - [Single File Upload](#single-file-upload)
  - [Drag and Drop Upload](#drag-and-drop-upload)
- [Multi-Step Forms](#multi-step-forms)

## File Upload Forms

### Single File Upload

Client-side checks give fast feedback, but anyone can bypass them. The upload endpoint must check authentication, size, and type again (inspect the file contents, not only the reported MIME type or extension).

```tsx
'use client';

import { useEffect, useState, type ChangeEvent, type FormEvent } from 'react';

const ACCEPTED_TYPES = ['image/png', 'image/jpeg', 'image/webp', 'application/pdf'];
const MAX_SIZE_BYTES = 5 * 1024 * 1024; // 5 MB

// Returns an error message, or null when the file is acceptable
export function validateFile(file: File): string | null {
  if (!ACCEPTED_TYPES.includes(file.type)) {
    return 'Choose a PNG, JPEG, WebP, or PDF file.';
  }
  if (file.size > MAX_SIZE_BYTES) {
    return 'The file must be 5 MB or smaller.';
  }
  return null;
}

function FileUploadForm() {
  const [file, setFile] = useState<File | null>(null);
  const [preview, setPreview] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [uploading, setUploading] = useState(false);

  // Object URL for image previews; revoked when the file changes or on unmount
  useEffect(() => {
    if (!file || !file.type.startsWith('image/')) {
      setPreview(null);
      return;
    }
    const url = URL.createObjectURL(file);
    setPreview(url);
    return () => URL.revokeObjectURL(url);
  }, [file]);

  const handleFileChange = (e: ChangeEvent<HTMLInputElement>) => {
    const selectedFile = e.target.files?.[0] ?? null;
    const validationError = selectedFile ? validateFile(selectedFile) : null;

    setError(validationError);
    setFile(validationError ? null : selectedFile);
    if (validationError) e.target.value = ''; // clear the rejected selection
  };

  const handleSubmit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    if (!file) return;

    setUploading(true);
    setError(null);
    const formData = new FormData();
    formData.append('file', file);

    try {
      const response = await fetch('/api/upload', {
        method: 'POST',
        body: formData, // the browser sets the multipart Content-Type
      });
      if (!response.ok) throw new Error(`Upload failed: ${response.status}`);
      await response.json();
    } catch {
      setError('Upload failed. Try again.');
    } finally {
      setUploading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <div>
        <label htmlFor="file">Select file</label>
        <input
          id="file"
          name="file"
          type="file"
          accept={ACCEPTED_TYPES.join(',')}
          aria-invalid={!!error}
          aria-describedby={error ? 'file-hint file-error' : 'file-hint'}
          onChange={handleFileChange}
        />
        <p id="file-hint">PNG, JPEG, WebP, or PDF, up to 5 MB.</p>
        {error && (
          <p id="file-error" role="alert">
            {error}
          </p>
        )}
      </div>

      {preview && (
        <div className="preview">
          <img src={preview} alt={`Preview of ${file?.name ?? 'selected image'}`} style={{ maxWidth: 200 }} />
        </div>
      )}

      {file && (
        <div className="file-info">
          <p>Name: {file.name}</p>
          <p>Size: {(file.size / 1024).toFixed(2)} KB</p>
          <p>Type: {file.type}</p>
        </div>
      )}

      <button type="submit" disabled={!file || uploading}>
        {uploading ? 'Uploading...' : 'Upload'}
      </button>
    </form>
  );
}
```

`accept` only filters the file picker; users can still choose other files and drag-and-drop ignores it, so `validateFile` runs on every selection.

### Drag and Drop Upload

The drop zone is only a pointer affordance. Keyboard and screen reader users select files through a real `<button>` that opens the hidden file input.

```tsx
'use client';

import { useState, useRef, type DragEvent, type ChangeEvent } from 'react';

function DragDropUpload() {
  const [files, setFiles] = useState<File[]>([]);
  const [isDragging, setIsDragging] = useState(false);
  const [rejectedMessage, setRejectedMessage] = useState<string | null>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  // `accept` does not apply to dropped files, so validate every file
  // (validateFile from the single-file example above)
  const addFiles = (incoming: File[]) => {
    const accepted = incoming.filter((f) => validateFile(f) === null);
    const rejected = incoming.filter((f) => validateFile(f) !== null);
    setFiles((prev) => [...prev, ...accepted]);
    setRejectedMessage(
      rejected.length > 0
        ? `Skipped ${rejected.map((f) => f.name).join(', ')}: use PNG, JPEG, WebP, or PDF up to 5 MB.`
        : null
    );
  };

  const handleDragOver = (e: DragEvent<HTMLDivElement>) => {
    e.preventDefault(); // required to allow dropping
  };

  const handleDragEnter = (e: DragEvent<HTMLDivElement>) => {
    e.preventDefault();
    setIsDragging(true);
  };

  const handleDragLeave = (e: DragEvent<HTMLDivElement>) => {
    // Ignore dragleave fired when moving between child elements
    if (e.currentTarget.contains(e.relatedTarget as Node | null)) return;
    setIsDragging(false);
  };

  const handleDrop = (e: DragEvent<HTMLDivElement>) => {
    e.preventDefault();
    setIsDragging(false);
    addFiles(Array.from(e.dataTransfer.files));
  };

  const handleFileSelect = (e: ChangeEvent<HTMLInputElement>) => {
    if (e.target.files) {
      addFiles(Array.from(e.target.files));
      e.target.value = ''; // allow re-selecting the same file
    }
  };

  const removeFile = (index: number) => {
    setFiles((prev) => prev.filter((_, i) => i !== index));
  };

  return (
    <div>
      <div
        className={`dropzone ${isDragging ? 'dragging' : ''}`}
        onDragEnter={handleDragEnter}
        onDragLeave={handleDragLeave}
        onDragOver={handleDragOver}
        onDrop={handleDrop}
      >
        <p id="dropzone-hint">Drag files here, or</p>
        <button
          type="button"
          aria-describedby="dropzone-hint"
          onClick={() => inputRef.current?.click()}
        >
          Choose files
        </button>
        <input
          ref={inputRef}
          type="file"
          multiple
          hidden
          aria-label="Choose files"
          accept="image/png,image/jpeg,image/webp,application/pdf"
          onChange={handleFileSelect}
        />
      </div>

      {rejectedMessage && <p role="alert">{rejectedMessage}</p>}

      {files.length > 0 && (
        <ul className="file-list" aria-live="polite">
          {files.map((file, index) => (
            <li key={`${file.name}-${file.lastModified}-${index}`}>
              <span>{file.name}</span>
              <span>{(file.size / 1024).toFixed(2)} KB</span>
              <button
                type="button"
                aria-label={`Remove ${file.name}`}
                onClick={() => removeFile(index)}
              >
                Remove
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
```

## Multi-Step Forms

```tsx
'use client';

import { useState } from 'react';
import { useForm, FormProvider, useFormContext } from 'react-hook-form';

interface CheckoutValues {
  // Step 1
  firstName: string;
  lastName: string;
  email: string;
  // Step 2
  address: string;
  city: string;
  zipCode: string;
  // Step 3
  cardNumber: string;
  expiryDate: string;
  cvv: string;
}

// One labelled, error-linked field; reused by every step
function Field({
  name,
  label,
  type = 'text',
  autoComplete,
}: {
  name: keyof CheckoutValues;
  label: string;
  type?: string;
  autoComplete?: string;
}) {
  const { register, formState: { errors } } = useFormContext<CheckoutValues>();
  const error = errors[name];
  const id = `checkout-${name}`;

  return (
    <div>
      <label htmlFor={id}>{label}</label>
      <input
        id={id}
        type={type}
        autoComplete={autoComplete}
        aria-invalid={!!error}
        aria-describedby={error ? `${id}-error` : undefined}
        {...register(name, { required: `${label} is required` })}
      />
      {error && <span id={`${id}-error`}>{error.message}</span>}
    </div>
  );
}

function Step1() {
  return (
    <div>
      <h2>Personal Information</h2>
      <Field name="firstName" label="First name" autoComplete="given-name" />
      <Field name="lastName" label="Last name" autoComplete="family-name" />
      <Field name="email" label="Email" type="email" autoComplete="email" />
    </div>
  );
}

function Step2() {
  return (
    <div>
      <h2>Shipping Address</h2>
      <Field name="address" label="Address" autoComplete="street-address" />
      <Field name="city" label="City" autoComplete="address-level2" />
      <Field name="zipCode" label="ZIP code" autoComplete="postal-code" />
    </div>
  );
}

function Step3() {
  return (
    <div>
      <h2>Payment</h2>
      <Field name="cardNumber" label="Card number" autoComplete="cc-number" />
      <Field name="expiryDate" label="Expiry (MM/YY)" autoComplete="cc-exp" />
      <Field name="cvv" label="CVV" autoComplete="cc-csc" />
    </div>
  );
}

const steps = [Step1, Step2, Step3];
const stepFields: (keyof CheckoutValues)[][] = [
  ['firstName', 'lastName', 'email'],
  ['address', 'city', 'zipCode'],
  ['cardNumber', 'expiryDate', 'cvv'],
];

function MultiStepForm() {
  const [currentStep, setCurrentStep] = useState(0);
  const methods = useForm<CheckoutValues>({ mode: 'onChange' });

  const StepComponent = steps[currentStep];

  const handleNext = async () => {
    const fields = stepFields[currentStep];
    const isValid = await methods.trigger(fields);

    if (isValid) {
      setCurrentStep((prev) => Math.min(prev + 1, steps.length - 1));
    }
  };

  const handlePrev = () => {
    setCurrentStep((prev) => Math.max(prev - 1, 0));
  };

  const onSubmit = (data: CheckoutValues) => {
    console.log('Form submitted:', data);
  };

  return (
    <FormProvider {...methods}>
      <form onSubmit={methods.handleSubmit(onSubmit)} noValidate>
        {/* Progress indicator */}
        <ol className="progress" aria-label="Checkout progress">
          {steps.map((_, index) => (
            <li
              key={index}
              className={`step ${index <= currentStep ? 'active' : ''}`}
              aria-current={index === currentStep ? 'step' : undefined}
            >
              Step {index + 1}
            </li>
          ))}
        </ol>

        <StepComponent />

        <div className="buttons">
          {currentStep > 0 && (
            <button type="button" onClick={handlePrev}>
              Previous
            </button>
          )}
          {currentStep < steps.length - 1 ? (
            <button type="button" onClick={handleNext}>
              Next
            </button>
          ) : (
            <button type="submit">Submit</button>
          )}
        </div>
      </form>
    </FormProvider>
  );
}
```
